import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/pet-owner-modules/pet_form_components/pet_form_field.dart';
import 'package:petpal/services/cloudinary.service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PetEditPanel extends StatefulWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const PetEditPanel({
    Key? key,
    required this.pet,
    required this.onCancel,
    required this.onSaved,
  }) : super(key: key);

  @override
  _PetEditPanelState createState() => _PetEditPanelState();
}

class _PetEditPanelState extends State<PetEditPanel> {
  final PetService _petService = PetService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _breedController;
  late TextEditingController _birthdateController;
  late TextEditingController _genderController;
  late TextEditingController _weightController;

  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _markingsController = TextEditingController();
  bool _isNeutered = false;
  String? _medicalRecordUrl;
  File? _medicalRecordFile;

  File? _imageFile;
  bool _isLoading = false;
  String? _imageUrl;
  DateTime? _selectedBirthdate;

  @override
  void initState() {
    super.initState();

    final petDetails = widget.pet['pet_details'] as Map<String, dynamic>?;

    _nameController = TextEditingController(text: widget.pet['name'] ?? '');
    _speciesController = TextEditingController(
      text: widget.pet['species'] ?? '',
    );
    _breedController = TextEditingController(text: widget.pet['breed'] ?? '');
    _genderController = TextEditingController(text: widget.pet['gender'] ?? '');
    _weightController = TextEditingController(
      text: (widget.pet['weight'] ?? 0.0).toString(),
    );
    _imageUrl = widget.pet['image_url'];

    if (petDetails != null) {
      _allergiesController.text = petDetails['allergies'] ?? '';
      _markingsController.text = petDetails['markings'] ?? '';
      _isNeutered = petDetails['is_neutered'] ?? false;
      _medicalRecordUrl = petDetails['medical_record_url'];
    }

    if (widget.pet['birthdate'] != null) {
      try {
        _selectedBirthdate = DateTime.parse(widget.pet['birthdate']);
        _birthdateController = TextEditingController(
          text: DateFormat('MMM d, yyyy').format(_selectedBirthdate!),
        );
      } catch (e) {
        _birthdateController = TextEditingController();
      }
    } else {
      _birthdateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _genderController.dispose();
    _birthdateController.dispose();
    _weightController.dispose();

    _allergiesController.dispose();
    _markingsController.dispose();

    super.dispose();
  }

  Future<void> _selectBirthdate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color.fromARGB(255, 50, 60, 70),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 37, 45, 50),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _pickMedicalRecordFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _medicalRecordFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updatePet() async {
    if (_nameController.text.isEmpty ||
        _speciesController.text.isEmpty ||
        _selectedBirthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields including birthdate'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String imageUrl = widget.pet['imageUrl'] ?? '';
    String medicalRecordUrl = widget.pet['medicalRecordUrl'] ?? '';

    try {
      if (_imageFile != null) {
        try {
          imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
        } catch (e) {}
      }

      if (_medicalRecordFile != null) {
        try {
          medicalRecordUrl = await _cloudinaryService.uploadImage(
            _medicalRecordFile!,
            folder: 'medical_records',
          );
        } catch (e) {}
      }

      await _petService.updatePet(
        petId: widget.pet['id'],
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        breed: _breedController.text.trim(),
        birthdate: _selectedBirthdate!,
        gender: _genderController.text.trim(),
        imageUrl: imageUrl,
        weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
        isNeutered: _isNeutered,
        allergies: _allergiesController.text.trim(),
        markings: _markingsController.text.trim(),
        medicalRecordUrl: medicalRecordUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet details updated successfully')),
        );

        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pet: ${e.toString()}')),
        );
      }
    }
  }

  void _viewMedicalRecord() {
    if (_medicalRecordUrl == null || _medicalRecordUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No medical record available to view')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Medical Record',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color.fromARGB(255, 44, 54, 60),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.visibility,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'View medical record',
                    onPressed: _viewMedicalRecord,
                  ),
                ],
              ),
              body: Container(
                color: const Color.fromARGB(255, 37, 45, 50),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      _medicalRecordUrl!,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load medical record',
                              style: TextStyle(color: Colors.red[300]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _launchUrl(_medicalRecordUrl!),
                              child: const Text('Try opening in browser'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening URL: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 54, 60),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Edit ${widget.pet['name'] ?? 'Pet'} Details",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    backgroundImage:
                        _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_imageUrl != null && _imageUrl!.isNotEmpty
                                ? NetworkImage(_imageUrl!)
                                : null),
                    child:
                        (_imageUrl == null || _imageUrl!.isEmpty) &&
                                _imageFile == null
                            ? Icon(
                              Icons.pets,
                              size: 50,
                              color: Colors.white.withOpacity(0.7),
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildFormField("Name", _nameController, Icons.pets),
            const SizedBox(height: 16),
            _buildFormField(
              "Animal Type",
              _speciesController,
              Icons.pets_outlined,
            ),
            const SizedBox(height: 16),
            _buildFormField("Breed", _breedController, Icons.pets_outlined),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _selectBirthdate,
              child: AbsorbPointer(
                child: _buildFormField(
                  "Birthdate",
                  _birthdateController,
                  Icons.calendar_today,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    "Gender",
                    _genderController,
                    Icons.people_alt_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    "Weight (kg)",
                    _weightController,
                    Icons.monitor_weight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.cut, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Neutered/Spayed",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isNeutered ? "Yes" : "No",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Switch(
                            value: _isNeutered,
                            onChanged: (value) {
                              setState(() {
                                _isNeutered = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            PetFormField(
              controller: _allergiesController,
              label: "Allergies",
              icon: Icons.health_and_safety,
              hint: "Enter any known allergies",
            ),

            PetFormField(
              controller: _markingsController,
              label: "Identifying Markings",
              icon: Icons.border_color,
              hint: "Enter any distinctive markings",
            ),

            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Medical Record",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_medicalRecordUrl != null && _medicalRecordUrl!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Medical record on file",
                            style: TextStyle(color: Colors.green[100]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'View medical record',
                          onPressed: _viewMedicalRecord,
                        ),
                      ],
                    ),
                  ),

                if (_medicalRecordFile != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "New medical record selected",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _medicalRecordFile = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _pickMedicalRecordFromGallery,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(
                    _medicalRecordUrl != null && _medicalRecordUrl!.isNotEmpty
                        ? "Replace Medical Record"
                        : "Upload Medical Record",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePet,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          "Save Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
