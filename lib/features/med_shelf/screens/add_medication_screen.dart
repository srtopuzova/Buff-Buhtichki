import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/date_helpers.dart';
import 'package:medshelf/core/utils/validators.dart';
import 'package:medshelf/features/med_shelf/models/medication_model.dart';
import 'package:medshelf/features/med_shelf/providers/medication_provider.dart';
import 'package:medshelf/shared/services/ocr_service.dart';
import 'package:medshelf/shared/widgets/loading_overlay.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _substanceCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();

  DateTime? _expiryDate;
  MedicationCategory _category = MedicationCategory.tablet;

  // Slot 0 = front, slot 1 = back — both required before saving.
  final _imageSlots = <File?>[null, null];
  String? _indications;

  bool _isScanning = false;
  bool _isSaving = false;
  String? _scanError;

  final _picker = ImagePicker();
  final _ocrService = OcrService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _substanceCtrl.dispose();
    _dosageCtrl.dispose();
    _manufacturerCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int slot, ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _imageSlots[slot] = File(picked.path);
      _isScanning = true;
      _scanError = null;
    });

    await _runOcrScan();
  }

  void _removeImage(int slot) {
    setState(() => _imageSlots[slot] = null);
  }

  Future<void> _runOcrScan() async {
    final images = _imageSlots.whereType<File>().toList();
    if (images.isEmpty) return;

    try {
      // Run OCR and (if back image is present) indications extraction in parallel.
      final backImage = _imageSlots[1];
      final futures = await Future.wait([
        _ocrService.extractMedicationInfo(images),
        if (backImage != null) _ocrService.extractIndications(backImage),
      ]);

      if (!mounted) return;

      final result = futures[0] as OcrMedicationResult;
      final indications =
          backImage != null ? futures[1] as String? : null;

      setState(() {
        if (result.name != null && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = result.name!;
        }
        if (result.activeSubstance != null && _substanceCtrl.text.isEmpty) {
          _substanceCtrl.text = result.activeSubstance!;
        }
        if (result.dosage != null && _dosageCtrl.text.isEmpty) {
          _dosageCtrl.text = result.dosage!;
        }
        if (result.manufacturer != null && _manufacturerCtrl.text.isEmpty) {
          _manufacturerCtrl.text = result.manufacturer!;
        }
        if (result.expiryRaw != null && _expiryDate == null) {
          final parsed = DateHelpers.tryParseExpiry(result.expiryRaw!);
          if (parsed != null) _expiryDate = parsed;
        }
        if (indications != null) _indications = indications;
        _isScanning = false;
      });

      if (result.name == null && result.expiryRaw == null) {
        setState(() => _scanError =
            'Could not extract information. Please fill in manually.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = 'Scan failed: ${e.toString()}';
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime(now.year + 1, now.month),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
      helpText: 'Select expiry date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.medShelf),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageSlots[0] == null || _imageSlots[1] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan both the front and back of the box'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final batch = MedicationBatch(
      id: const Uuid().v4(),
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
    );
    final medication = MedicationModel(
      id: '',
      userId: '',
      name: _nameCtrl.text.trim(),
      activeSubstance: _substanceCtrl.text.trim().isEmpty
          ? null
          : _substanceCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      indications: _indications,
      batches: [batch],
      category: _category,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<MedicationProvider>().addMedication(
          medication: medication,
          imageFile: _imageSlots[0], // front photo saved as the card image
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<MedicationProvider>().errorMessage ??
              'Failed to save'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSaving,
      message: 'Saving medication...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.medShelf,
          foregroundColor: Colors.white,
          title: const Text('Add Medication',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScanSection(
                  frontImage: _imageSlots[0],
                  backImage: _imageSlots[1],
                  isScanning: _isScanning,
                  scanError: _scanError,
                  onPickFront: (src) => _pickImage(0, src),
                  onPickBack: (src) => _pickImage(1, src),
                  onRemoveFront: () => _removeImage(0),
                  onRemoveBack: () => _removeImage(1),
                ),
                const SizedBox(height: 20),
                _SectionHeader(title: 'Medication Details'),
                const SizedBox(height: 12),
                _buildField(
                  controller: _nameCtrl,
                  label: 'Name *',
                  hint: 'e.g. Paracetamol',
                  validator: (v) => Validators.required(v, fieldName: 'Name'),
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _substanceCtrl,
                  label: 'Active Substance',
                  hint: 'e.g. Acetaminophen',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _dosageCtrl,
                        label: 'Dosage',
                        hint: 'e.g. 500mg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _quantityCtrl,
                        label: 'Quantity *',
                        hint: 'e.g. 30',
                        keyboardType: TextInputType.number,
                        validator: Validators.positiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _manufacturerCtrl,
                  label: 'Manufacturer',
                  hint: 'e.g. Bayer',
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Expiry Date *'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.medShelf, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _expiryDate != null
                              ? DateFormat('dd MMMM yyyy').format(_expiryDate!)
                              : 'Select expiry date',
                          style: TextStyle(
                            color: _expiryDate != null
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Category'),
                const SizedBox(height: 8),
                _CategorySelector(
                  selected: _category,
                  onChanged: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _notesCtrl,
                  label: 'Notes',
                  hint: 'Any additional notes...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: const Text('Save Medication'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─── Scan section ─────────────────────────────────────────────────────────────

class _ScanSection extends StatelessWidget {
  final File? frontImage;
  final File? backImage;
  final bool isScanning;
  final String? scanError;
  final void Function(ImageSource) onPickFront;
  final void Function(ImageSource) onPickBack;
  final VoidCallback onRemoveFront;
  final VoidCallback onRemoveBack;

  const _ScanSection({
    required this.frontImage,
    required this.backImage,
    required this.isScanning,
    required this.scanError,
    required this.onPickFront,
    required this.onPickBack,
    required this.onRemoveFront,
    required this.onRemoveBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.medShelfGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.document_scanner_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Scan Box',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Scan front and back for auto-fill',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ImageSlot(
                  label: 'Front',
                  image: frontImage,
                  onPick: onPickFront,
                  onRemove: onRemoveFront,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImageSlot(
                  label: 'Back',
                  image: backImage,
                  onPick: onPickBack,
                  onRemove: onRemoveBack,
                ),
              ),
            ],
          ),
          if (isScanning) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 10),
                Text('Analysing image...',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ] else if (scanError != null) ...[
            const SizedBox(height: 8),
            Text(scanError!,
                style:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  final String label;
  final File? image;
  final void Function(ImageSource) onPick;
  final VoidCallback onRemove;

  const _ImageSlot({
    required this.label,
    required this.image,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (image != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image!,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.white54, size: 26),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconBtn(Icons.camera_alt_rounded,
                        () => onPick(ImageSource.camera)),
                    const SizedBox(width: 16),
                    _iconBtn(Icons.photo_library_rounded,
                        () => onPick(ImageSource.gallery)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }
}

// ─── Category selector ────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final MedicationCategory selected;
  final ValueChanged<MedicationCategory> onChanged;

  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MedicationCategory.values.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.medShelf : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.medShelf : AppColors.border,
              ),
            ),
            child: Text(
              cat.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
