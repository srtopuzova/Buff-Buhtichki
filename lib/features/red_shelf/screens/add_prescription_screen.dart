import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/validators.dart';
import 'package:medshelf/features/red_shelf/models/prescription_model.dart';
import 'package:medshelf/features/red_shelf/providers/prescription_provider.dart';
import 'package:medshelf/shared/services/ocr_service.dart';
import 'package:medshelf/shared/widgets/loading_overlay.dart';

class _ItemCtrl {
  final TextEditingController name = TextEditingController();
  final TextEditingController dosage = TextEditingController();
  final TextEditingController frequency = TextEditingController();
  final TextEditingController duration = TextEditingController();
  final TextEditingController instructions = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
  }
}

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() =>
      _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final List<_ItemCtrl> _items = [_ItemCtrl()];

  File? _imageFile;
  bool _isScanning = false;
  bool _isSaving = false;
  String? _scanError;
  TimeOfDay? _reminderTime;

  final _picker = ImagePicker();
  final _ocrService = OcrService();

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _patientCtrl.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
      _isScanning = true;
      _scanError = null;
    });

    try {
      final result = await _ocrService.extractPrescriptionInfo(_imageFile!);
      if (!mounted) return;
      setState(() {
        if (result.doctorName != null && _doctorCtrl.text.isEmpty) {
          _doctorCtrl.text = result.doctorName!;
        }
        if (result.patientName != null && _patientCtrl.text.isEmpty) {
          _patientCtrl.text = result.patientName!;
        }
        if (result.items.isNotEmpty) {
          for (final c in _items) {
            c.dispose();
          }
          _items.clear();
          for (final item in result.items) {
            final ctrl = _ItemCtrl();
            ctrl.name.text = item.name;
            if (item.dosage != null) ctrl.dosage.text = item.dosage!;
            if (item.frequency != null) ctrl.frequency.text = item.frequency!;
            if (item.duration != null) ctrl.duration.text = item.duration!;
            if (item.instructions != null) {
              ctrl.instructions.text = item.instructions!;
            }
            _items.add(ctrl);
          }
        } else {
          _scanError =
              'No medications found. Please fill in manually.';
        }
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = 'Scan failed: ${e.toString()}';
      });
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemCtrl()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.redShelf),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final validItems =
        _items.where((c) => c.name.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one medication'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final rxItems = validItems
        .map((c) => PrescribedItem(
              name: c.name.text.trim(),
              dosage: c.dosage.text.trim().isEmpty
                  ? null
                  : c.dosage.text.trim(),
              frequency: c.frequency.text.trim().isEmpty
                  ? null
                  : c.frequency.text.trim(),
              duration: c.duration.text.trim().isEmpty
                  ? null
                  : c.duration.text.trim(),
              instructions: c.instructions.text.trim().isEmpty
                  ? null
                  : c.instructions.text.trim(),
            ))
        .toList();

    final prescription = PrescriptionModel(
      id: '',
      userId: '',
      items: rxItems,
      doctorName: _doctorCtrl.text.trim().isEmpty
          ? null
          : _doctorCtrl.text.trim(),
      patientName: _patientCtrl.text.trim().isEmpty
          ? null
          : _patientCtrl.text.trim(),
      status: PrescriptionStatus.pending,
      doseRecords: const [],
      reminderHour: _reminderTime?.hour,
      reminderMinute: _reminderTime?.minute,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success =
        await context.read<PrescriptionProvider>().addPrescription(
              prescription: prescription,
              imageFile: _imageFile,
            );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription added — pending pickup'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<PrescriptionProvider>().errorMessage ??
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
      message: 'Saving prescription...',
      color: AppColors.redShelf,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.redShelf,
          foregroundColor: Colors.white,
          title: const Text('Add Prescription',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
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
                _RxScanSection(
                  imageFile: _imageFile,
                  isScanning: _isScanning,
                  scanError: _scanError,
                  onCamera: () => _pickAndScan(ImageSource.camera),
                  onGallery: () => _pickAndScan(ImageSource.gallery),
                ),
                const SizedBox(height: 20),
                // Doctor / Patient
                _label('Doctor Name'),
                const SizedBox(height: 6),
                _textField(_doctorCtrl, hint: 'e.g. Dr. Ivanov'),
                const SizedBox(height: 12),
                _label('Patient Name'),
                const SizedBox(height: 6),
                _textField(_patientCtrl, hint: 'e.g. Ivan Petrov'),
                const SizedBox(height: 20),
                // Medications section
                Row(
                  children: [
                    const Text(
                      'Medications',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: AppColors.redShelf),
                      label: const Text('Add',
                          style: TextStyle(
                              color: AppColors.redShelf, fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Item cards
                for (int i = 0; i < _items.length; i++)
                  _MedItemCard(
                    index: i,
                    ctrl: _items[i],
                    canRemove: _items.length > 1,
                    onRemove: () => _removeItem(i),
                  ),
                const SizedBox(height: 16),
                // Reminder time
                _label('Daily Reminder (Optional)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickReminderTime,
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
                        const Icon(Icons.alarm_rounded,
                            color: AppColors.redShelf, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _reminderTime != null
                              ? _reminderTime!.format(context)
                              : 'Set reminder time',
                          style: TextStyle(
                            color: _reminderTime != null
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (_reminderTime != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _reminderTime = null),
                            child: const Icon(Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redShelf),
                    child: const Text('Save Prescription'),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );

  Widget _textField(TextEditingController ctrl,
      {String? hint, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _MedItemCard extends StatelessWidget {
  final int index;
  final _ItemCtrl ctrl;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MedItemCard({
    required this.index,
    required this.ctrl,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.redShelfLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: AppColors.redShelf,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Medication',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _fieldLabel('Name *'),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl.name,
            validator: (v) => Validators.required(v, fieldName: 'Name'),
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration:
                const InputDecoration(hintText: 'e.g. Amoxicillin'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Dosage'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: ctrl.dosage,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration:
                          const InputDecoration(hintText: 'e.g. 500mg'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Frequency'),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: ctrl.frequency,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                          hintText: 'e.g. twice daily'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fieldLabel('Duration'),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl.duration,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration:
                const InputDecoration(hintText: 'e.g. 7 days'),
          ),
          const SizedBox(height: 10),
          _fieldLabel('Instructions'),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl.instructions,
            maxLines: 2,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
                hintText: 'e.g. take with food, avoid alcohol'),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
      );
}

class _RxScanSection extends StatelessWidget {
  final File? imageFile;
  final bool isScanning;
  final String? scanError;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _RxScanSection({
    required this.imageFile,
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
        gradient: AppColors.redShelfGradient,
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
              Text('Scan Prescription',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'Auto-fill all medications from the prescription image',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          if (imageFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(imageFile!,
                  height: 100, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          if (isScanning)
            const Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 10),
                Text('Analysing prescription...',
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Camera',
                        style:
                            TextStyle(color: Colors.white, fontSize: 13)),
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
                        style:
                            TextStyle(color: Colors.white, fontSize: 13)),
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
