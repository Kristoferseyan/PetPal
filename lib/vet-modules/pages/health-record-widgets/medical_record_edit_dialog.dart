import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/services/cloudinary.service.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';

class MedicalRecordEditDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final MedicalService medicalService;

  const MedicalRecordEditDialog({
    Key? key,
    required this.record,
    required this.medicalService,
  }) : super(key: key);

  @override
  State<MedicalRecordEditDialog> createState() =>
      _MedicalRecordEditDialogState();
}

class _MedicalRecordEditDialogState extends State<MedicalRecordEditDialog> {
  final _editFormKey = GlobalKey<FormState>();
  final _editDiagnosisController = TextEditingController();
  final _editTreatmentController = TextEditingController();
  final _editNotesController = TextEditingController();

  String? _currentImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _editDiagnosisController.text = widget.record['diagnosis'] ?? '';
    _editTreatmentController.text = widget.record['treatment'] ?? '';
    _editNotesController.text = widget.record['notes'] ?? '';
    _currentImageUrl = widget.record['image_url'];
  }

  @override
  void dispose() {
    _editDiagnosisController.dispose();
    _editTreatmentController.dispose();
    _editNotesController.dispose();
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

  Future<void> _updateMedicalRecord() async {
    if (!_editFormKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      String? imageUrl;
      bool removeImage = false;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      } else if (_currentImageUrl == null) {
        removeImage = true;
      }

      final updatedRecord = await widget.medicalService.updateMedicalRecord(
        recordId: widget.record['id'],
        diagnosis: _editDiagnosisController.text,
        treatment: _editTreatmentController.text,
        notes: _editNotesController.text,
        imageUrl:
            imageUrl ?? (_currentImageUrl != null ? _currentImageUrl : null),
        removeImage: removeImage,
      );

      Navigator.pop(context, true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical record updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update medical record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      Navigator.pop(context, false);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _editFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Medical Record',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFormField(
                controller: _editDiagnosisController,
                label: 'Diagnosis',
                hint: 'Enter the diagnosis or health condition',
                icon: Icons.medical_information,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _editTreatmentController,
                label: 'Treatment Plan',
                hint: 'Enter prescribed treatment or medication',
                icon: Icons.healing,
                isRequired: true,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                controller: _editNotesController,
                label: 'Additional Notes',
                hint: 'Enter any additional notes or observations',
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              if (_currentImageUrl != null && _selectedImage == null) ...[
                Row(
                  children: [
                    Icon(Icons.image, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Current Image',
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
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentImageUrl = null;
                          });
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
                const SizedBox(height: 20),
              ],

              if (_selectedImage != null) ...[
                Row(
                  children: [
                    Icon(Icons.image, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'New Image',
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
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
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
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _showImageSourceDialog,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _selectedImage == null && _currentImageUrl == null
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
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isUploading || _isLoading
                              ? null
                              : _updateMedicalRecord,
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
                      label: const Text('Update Record'),
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
              const SizedBox(height: 30),
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
