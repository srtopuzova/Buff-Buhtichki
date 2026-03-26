import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  final List<File> _scannedImages = [];
  File? _primaryImage;
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

  Future<void> _pickAndScanImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _scannedImages.add(file);
      _primaryImage ??= file;
      _isScanning = true;
      _scanError = null;
    });

    try {
      final result = await _ocrService.extractMedicationInfo(_scannedImages);
      if (!mounted) return;
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
      expiryDate: _expiryDate!,
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      category: _category,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await context.read<MedicationProvider>().addMedication(
          medication: medication,
          imageFile: _primaryImage,
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
                // Scan section
                _ScanSection(
                  images: _scannedImages,
                  isScanning: _isScanning,
                  scanError: _scanError,
                  onCamera: () => _pickAndScanImage(ImageSource.camera),
                  onGallery: () => _pickAndScanImage(ImageSource.gallery),
                ),
                const SizedBox(height: 20),
                // Form fields
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
                // Expiry date
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
                // Category
                _SectionHeader(title: 'Category'),
                const SizedBox(height: 8),
                _CategorySelector(
                  selected: _category,
                  onChanged: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 16),
                // Notes
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

class _ScanSection extends StatelessWidget {
  final List<File> images;
  final bool isScanning;
  final String? scanError;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ScanSection({
    required this.images,
    required this.isScanning,
    required this.scanError,
    required this.onCamera,
    required this.onGallery,
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
              Text('Scan Box (Optional)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Scan up to 2 sides for auto-fill',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          if (images.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(images[i],
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isScanning)
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
            )
          else ...[
            if (scanError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(scanError!,
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 12)),
              ),
            if (images.length < 2)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                      label: const Text('Camera',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_rounded,
                          color: Colors.white, size: 16),
                      label: const Text('Gallery',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

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
