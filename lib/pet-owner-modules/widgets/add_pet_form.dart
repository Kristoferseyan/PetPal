import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petpal/services/cloudinary.service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';

class AddPetForm extends StatefulWidget {
  final String ownerId;
  final VoidCallback onPetAdded;

  const AddPetForm({Key? key, required this.ownerId, required this.onPetAdded})
    : super(key: key);

  @override
  _AddPetFormState createState() => _AddPetFormState();
}

class _AddPetFormState extends State<AddPetForm> {
  final PetService _petService = PetService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _markingsController = TextEditingController();

  File? _imageFile;
  File? _medicalRecordFile;
  bool _isLoading = false;
  bool _isNeutered = false;

  String? _selectedSpecies;
  String? _selectedBreed;
  DateTime? _selectedBirthdate;

  final List<String> _speciesOptions = ['Dog', 'Cat', 'Other'];

  final Map<String, List<String>> _breedOptions = {
    'Dog': [
      'Labrador Retriever',
      'German Shepherd',
      'Golden Retriever',
      'Bulldog',
      'Beagle',
      'Poodle',
      'Rottweiler',
      'Yorkshire Terrier',
      'Boxer',
      'Dachshund',
      'Shih Tzu',
      'Chihuahua',
      'Mixed Breed',
      'Other',
    ],
    'Cat': [
      'Persian',
      'Maine Coon',
      'Siamese',
      'Ragdoll',
      'Bengal',
      'Abyssinian',
      'Birman',
      'Sphynx',
      'Scottish Fold',
      'British Shorthair',
      'Other',
    ],
    'Bird': [
      'Parakeet',
      'Canary',
      'Cockatiel',
      'Lovebird',
      'Finch',
      'Parrot',
      'Other',
    ],
    'Rabbit': [
      'Holland Lop',
      'Mini Rex',
      'Dutch',
      'Lionhead',
      'Netherland Dwarf',
      'Other',
    ],
    'Guinea Pig': ['American', 'Abyssinian', 'Peruvian', 'Teddy', 'Other'],
    'Hamster': [
      'Syrian',
      'Dwarf Campbell Russian',
      'Dwarf Winter White',
      'Roborovski',
      'Chinese',
      'Other',
    ],
    'Turtle': ['Red-Eared Slider', 'Box Turtle', 'Painted Turtle', 'Other'],
    'Fish': [
      'Goldfish',
      'Betta',
      'Guppy',
      'Angelfish',
      'Tetra',
      'Molly',
      'Other',
    ],
    'Other': ['Other'],
  };

  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Unknown'];

  void _updateSelectedGender(String? gender) {
    setState(() {
      _selectedGender = gender;
      if (gender != null) {
        _genderController.text = gender;
      }
    });
  }

  void _updateBreedOptions(String? species) {
    setState(() {
      _selectedSpecies = species;
      _selectedBreed = null;
      _breedController.text = '';

      if (species == 'Other') {
        _speciesController.text = '';
      }
    });
  }

  void _updateSelectedBreed(String? breed) {
    setState(() {
      _selectedBreed = breed;
      if (breed != null) {
        if (breed == 'Other') {
          _breedController.text = '';
        } else {
          _breedController.text = breed;
        }
      }
    });
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

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      try {
        Directory docDir = await getApplicationDocumentsDirectory();
        String docPath = docDir.path;

        DateTime now = DateTime.now();
        String timestamp = now.toIso8601String();
        String fileName = '$timestamp${pickedFile.name}';
        String filePath = '$docPath/$fileName';

        _imageFile!.copySync(filePath);

        Map<String, dynamic> metadata = {
          'filePath': filePath,
          'timestamp': timestamp,
        };
        String metadataFilePath = '$docPath/$fileName.metadata';
        File(metadataFilePath).writeAsStringSync(jsonEncode(metadata));
      } catch (e) {}
    }
  }

  Future<void> _pickMedicalRecordFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _medicalRecordFile = File(pickedFile.path);
      });

      try {
        Directory docDir = await getApplicationDocumentsDirectory();
        String docPath = docDir.path;

        DateTime now = DateTime.now();
        String timestamp = now.toIso8601String();
        String fileName = 'med_$timestamp${pickedFile.name}';
        String filePath = '$docPath/$fileName';

        _medicalRecordFile!.copySync(filePath);

        Map<String, dynamic> metadata = {
          'filePath': filePath,
          'timestamp': timestamp,
          'type': 'medical_record',
        };
        String metadataFilePath = '$docPath/$fileName.metadata';
        File(metadataFilePath).writeAsStringSync(jsonEncode(metadata));
      } catch (e) {}
    }
  }

  Future<void> _addPet() async {
    final name = _nameController.text.trim();
    final gender = _selectedGender ?? _genderController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final allergies = _allergiesController.text.trim();
    final markings = _markingsController.text.trim();

    final species = _selectedSpecies ?? _speciesController.text.trim();
    final breed = _selectedBreed ?? _breedController.text.trim();

    if (name.isEmpty || species.isEmpty || _selectedBirthdate == null) {
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

    String imageUrl = '';
    String medicalRecordUrl = '';

    try {
      if (_imageFile != null) {
        try {
          imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (_medicalRecordFile != null) {
        try {
          medicalRecordUrl = await _cloudinaryService.uploadImage(
            _medicalRecordFile!,
            folder: 'medical_records',
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to upload medical record, but continuing with pet creation',
              ),
            ),
          );
        }
      }

      await _petService.addPet(
        ownerId: widget.ownerId,
        name: name,
        species: species,
        breed: breed,
        birthdate: _selectedBirthdate!,
        gender: gender,
        imageUrl: imageUrl,
        weight: weight,
        isNeutered: _isNeutered,
        allergies: allergies,
        markings: markings,
        medicalRecordUrl: medicalRecordUrl,
      );

      _nameController.clear();
      _speciesController.clear();
      _breedController.clear();
      _genderController.clear();
      _birthdateController.clear();
      _weightController.clear();
      _allergiesController.clear();
      _markingsController.clear();
      setState(() {
        _imageFile = null;
        _medicalRecordFile = null;
        _isLoading = false;
        _selectedSpecies = null;
        _selectedBreed = null;
        _selectedGender = null;
        _selectedBirthdate = null;
        _isNeutered = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet added successfully')));

      widget.onPetAdded();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add pet: ${e.toString()}')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Add a New Pet",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            PetFormField(
              controller: _nameController,
              label: "Pet Name",
              icon: Icons.pets,
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      _selectedSpecies == 'Other'
                          ? PetFormField(
                            controller: _speciesController,
                            label: "Custom Animal Type",
                            icon: Icons.eco,
                            hintText: "Enter animal type",
                          )
                          : DropdownPetFormField(
                            label: "Animal Type",
                            icon: Icons.eco,
                            items: _speciesOptions,
                            value: _selectedSpecies,
                            onChanged: _updateBreedOptions,
                            hintText: "Select animal type",
                          ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child:
                      _selectedBreed == 'Other'
                          ? PetFormField(
                            controller: _breedController,
                            label: "Custom Breed",
                            icon: Icons.pets_outlined,
                            hintText: "Enter breed",
                          )
                          : DropdownPetFormField(
                            label: "Breed",
                            icon: Icons.pets_outlined,
                            items:
                                _selectedSpecies != null
                                    ? _breedOptions[_selectedSpecies]!
                                    : ['Select animal type first'],
                            value: _selectedBreed,
                            onChanged: _updateSelectedBreed,
                            hintText:
                                _selectedSpecies != null
                                    ? "Select breed"
                                    : "Select animal type first",
                          ),
                ),
              ],
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownPetFormField(
                    label: "Gender",
                    icon: Icons.people,
                    items: _genderOptions,
                    value: _selectedGender,
                    onChanged: _updateSelectedGender,
                    hintText: "Select gender",
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cut,
                                size: 16,
                                color: AppColors.primary,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
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
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectBirthdate,
                    child: AbsorbPointer(
                      child: PetFormField(
                        controller: _birthdateController,
                        label: "Birthdate",
                        icon: Icons.calendar_today,
                        hintText: "Select birthdate",
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: PetFormField(
                    controller: _weightController,
                    label: "Weight (kg)",
                    keyboardType: TextInputType.number,
                    icon: Icons.monitor_weight,
                  ),
                ),
              ],
            ),

            PetFormField(
              controller: _allergiesController,
              label: "Allergies",
              icon: Icons.health_and_safety,
              hintText: "Enter any known allergies",
            ),

            PetFormField(
              controller: _markingsController,
              label: "Identifying Markings",
              icon: Icons.border_color,
              hintText: "Enter any distinctive markings",
            ),

            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Text(
                    "Pet Photo",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_imageFile != null)
                    Container(
                      width: 150,
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    )
                  else
                    Container(
                      width: 150,
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[700]!, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      "Select Photo",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Center(
              child: Column(
                children: [
                  Text(
                    "Medical Record (Optional)",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_medicalRecordFile != null)
                    Container(
                      width: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description, color: Colors.green),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Medical record selected",
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() {
                                _medicalRecordFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[700]!, width: 2),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Upload medical record",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ElevatedButton.icon(
                    onPressed: _pickMedicalRecordFromGallery,
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text(
                      "Upload Medical Record",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addPet,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isLoading ? "Adding..." : "Add Pet",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PetFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final String? hintText;

  const PetFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText ?? "Enter $label",
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[800]!.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownPetFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final String hintText;

  const DropdownPetFormField({
    Key? key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
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
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border:
                  value != null
                      ? Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      )
                      : Border.all(color: Colors.transparent, width: 1),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                border: InputBorder.none,
              ),
              hint: Text(
                hintText,
                style: TextStyle(color: Colors.grey[350], fontSize: 14),
              ),
              dropdownColor: const Color.fromARGB(255, 50, 60, 65),
              items:
                  items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
