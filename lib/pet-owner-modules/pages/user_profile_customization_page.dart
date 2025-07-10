import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:petpal/services/cloudinary.service.dart';

class UserProfileCustomizationPage extends StatefulWidget {
  final bool isFirstTimeSetup;

  const UserProfileCustomizationPage({Key? key, this.isFirstTimeSetup = false})
    : super(key: key);

  @override
  State<UserProfileCustomizationPage> createState() =>
      _UserProfileCustomizationPageState();
}

class _UserProfileCustomizationPageState
    extends State<UserProfileCustomizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _gender;
  DateTime? _birthdate;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String _userId = '';
  File? _selectedImageFile;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final userDetails = await _authService.getUserDetails();
      if (userDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load user details')),
        );
        return;
      }

      _userId = userDetails['id'];

      final profileData =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('user_id', _userId)
              .maybeSingle();

      if (profileData != null) {
        setState(() {
          _fullNameController.text =
              profileData['full_name'] ?? userDetails['full_name'] ?? '';
          _phoneController.text = profileData['phone'] ?? '';
          _addressController.text = profileData['address'] ?? '';
          _gender = profileData['gender'];

          if (profileData['birthdate'] != null) {
            _birthdate = DateTime.parse(profileData['birthdate']);
          }

          _profileImageUrl = profileData['profile_image'];
        });
      } else {
        _fullNameController.text = userDetails['full_name'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isSaving = true);

      String? uploadedImageUrl;
      if (_selectedImageFile != null) {
        uploadedImageUrl = await _uploadProfileImage();
        if (uploadedImageUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final Map<String, dynamic> profileData = {
        'user_id': _userId,
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        'birthdate': _birthdate?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),

        'profile_image': uploadedImageUrl ?? _profileImageUrl,
      };

      final existingProfile =
          await _supabase
              .from('user_profiles')
              .select()
              .eq('user_id', _userId)
              .maybeSingle();

      if (existingProfile == null) {
        profileData['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('user_profiles').insert(profileData);
      } else {
        await _supabase
            .from('user_profiles')
            .update(profileData)
            .eq('user_id', _userId);
      }

      await _authService.updateUserName(_fullNameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isFirstTimeSetup) {
          Navigator.pushReplacementNamed(context, '/petowner/dashboard');
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1923),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color.fromARGB(255, 45, 55, 60),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 37, 45, 50),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  Future<void> _selectImage() async {
    final XFile? pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImageFile = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImageFile == null) return _profileImageUrl;

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrl = await _cloudinaryService.uploadImage(
        _selectedImageFile!,
        preset: 'profile_images',
        folder: 'profiles',
      );
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 37, 45, 50),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.isFirstTimeSetup ? 'Complete Your Profile' : 'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        leading:
            widget.isFirstTimeSetup
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildProfileForm(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _selectImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[800],
                  backgroundImage:
                      _selectedImageFile != null
                          ? FileImage(_selectedImageFile!)
                          : (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null),
                  child:
                      (_selectedImageFile == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty))
                          ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _selectImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isFirstTimeSetup
                ? 'Complete your profile information'
                : 'Update your personal details',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          if (_selectedImageFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'New image selected',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(),
        const SizedBox(height: 16),
        _buildBirthdateSelector(),
        const SizedBox(height: 24),

        _buildSectionTitle('Contact Information'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.home,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
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
              '$label${isRequired ? ' *' : ''}',
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
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

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'Gender',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 55, 65, 70),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _gender,
            isExpanded: true,
            dropdownColor: const Color.fromARGB(255, 55, 65, 70),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            items:
                _genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _gender = newValue;
              });
            },
            hint: Text(
              'Select gender',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdateSelector() {
    final formattedDate =
        _birthdate != null ? DateFormat('MMMM d, y').format(_birthdate!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cake, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'Date of Birth',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 55, 65, 70),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate ?? 'Select date of birth',
                  style: TextStyle(
                    color:
                        formattedDate != null ? Colors.white : Colors.grey[500],
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey,
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Save Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}
