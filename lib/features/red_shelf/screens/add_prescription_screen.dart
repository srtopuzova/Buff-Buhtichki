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

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() =>
      _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _frequencyCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  File? _imageFile;
  bool _isScanning = false;
  bool _isSaving = false;
  String? _scanError;
  TimeOfDay? _reminderTime;

  final _picker = ImagePicker();
  final _ocrService = OcrService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _frequencyCtrl.dispose();
    _durationCtrl.dispose();
    _doctorCtrl.dispose();
    _patientCtrl.dispose();
    _instructionsCtrl.dispose();
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
      final result =
          await _ocrService.extractPrescriptionInfo(_imageFile!);
      if (!mounted) return;
      setState(() {
        if (result.medicationName != null && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = result.medicationName!;
        }
        if (result.dosage != null && _dosageCtrl.text.isEmpty) {
          _dosageCtrl.text = result.dosage!;
        }
        if (result.frequency != null && _frequencyCtrl.text.isEmpty) {
          _frequencyCtrl.text = result.frequency!;
        }
        if (result.duration != null && _durationCtrl.text.isEmpty) {
          _durationCtrl.text = result.duration!;
        }
        if (result.doctorName != null && _doctorCtrl.text.isEmpty) {
          _doctorCtrl.text = result.doctorName!;
        }
        if (result.patientName != null && _patientCtrl.text.isEmpty) {
          _patientCtrl.text = result.patientName!;
        }
        if (result.instructions != null &&
            _instructionsCtrl.text.isEmpty) {
          _instructionsCtrl.text = result.instructions!;
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
    setState(() => _isSaving = true);

    final prescription = PrescriptionModel(
      id: '',
      userId: '',
      medicationName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim().isEmpty
          ? null
          : _dosageCtrl.text.trim(),
      frequency: _frequencyCtrl.text.trim().isEmpty
          ? null
          : _frequencyCtrl.text.trim(),
      duration: _durationCtrl.text.trim().isEmpty
          ? null
          : _durationCtrl.text.trim(),
      doctorName: _doctorCtrl.text.trim().isEmpty
          ? null
          : _doctorCtrl.text.trim(),
      patientName: _patientCtrl.text.trim().isEmpty
          ? null
          : _patientCtrl.text.trim(),
      instructions: _instructionsCtrl.text.trim().isEmpty
          ? null
          : _instructionsCtrl.text.trim(),
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
                _field(_nameCtrl, 'Medication Name *',
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Medication name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field(_dosageCtrl, 'Dosage',
                            hint: 'e.g. 500mg')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_frequencyCtrl, 'Frequency',
                            hint: 'e.g. twice daily')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_durationCtrl, 'Duration', hint: 'e.g. 7 days'),
                const SizedBox(height: 12),
                _field(_doctorCtrl, 'Doctor Name'),
                const SizedBox(height: 12),
                _field(_patientCtrl, 'Patient Name'),
                const SizedBox(height: 12),
                _field(_instructionsCtrl, 'Instructions',
                    maxLines: 3,
                    hint: 'e.g. take with food, avoid alcohol'),
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

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          maxLines: maxLines,
          style:
              const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
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
          const Text('Auto-fill details from the prescription image',
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