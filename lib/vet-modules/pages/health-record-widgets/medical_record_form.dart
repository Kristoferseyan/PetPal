import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/services/cloudinary.service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalRecordForm extends StatefulWidget {
  final String petId;
  final String petName;
  final Function() onRecordSaved;

  const MedicalRecordForm({
    Key? key,
    required this.petId,
    required this.petName,
    required this.onRecordSaved,
  }) : super(key: key);

  @override
  State<MedicalRecordForm> createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends State<MedicalRecordForm> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImage!,
        preset: 'medical_records',
        folder: 'medical_records',
      );

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      String? imageUrl;
      if (_selectedImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image, please wait...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        imageUrl = await _uploadImage();

        if (imageUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Warning: Image upload failed, but record will still be saved',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      final Map<String, dynamic> recordData = {
        'pet_id': widget.petId,
        'diagnosis': _diagnosisController.text,
        'treatment': _treatmentController.text,
        'notes': _notesController.text,
        'created_at': DateTime.now().toIso8601String(),
        'archived': false,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        recordData['image_url'] = imageUrl;
      }

      await _supabase.from('medical_history').insert(recordData);

      _diagnosisController.clear();
      _treatmentController.clear();
      _notesController.clear();
      setState(() => _selectedImage = null);

      widget.onRecordSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save medical record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        _showImagePreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 44, 54, 60),
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showImagePreview() {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 44, 54, 60),
            title: const Text(
              'Selected Image',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This image will be uploaded when you save the medical record.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  setState(() => _selectedImage = null);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text(
                  'Keep',
                  style: TextStyle(color: AppColors.primary),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        color: const Color.fromARGB(255, 44, 54, 60),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medical_services,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Health Record for ${widget.petName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildFormField(
                controller: _diagnosisController,
                label: 'Diagnosis',
                hint: 'Enter the diagnosis or health condition',
                icon: Icons.medical_information,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _treatmentController,
                label: 'Treatment Plan',
                hint: 'Enter prescribed treatment or medication',
                icon: Icons.healing,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Enter any additional notes or observations',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveMedicalRecord,
                      icon:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: const Text('Save Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImage != null) ...[
                    Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Image',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedImage = null);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isUploading ? null : _showImageSourceDialog,
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.camera_alt),
                          label: Text(
                            _selectedImage == null
                                ? 'Add Image'
                                : 'Change Image',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              label + (isRequired ? ' *' : ''),
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
            filled: true,
            fillColor: const Color.fromARGB(255, 55, 65, 70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator:
              isRequired
                  ? (value) =>
                      value?.isEmpty ?? true ? 'This field is required' : null
                  : null,
        ),
      ],
    );
  }
}
