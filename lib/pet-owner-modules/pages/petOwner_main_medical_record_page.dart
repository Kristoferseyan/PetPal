import 'package:flutter/material.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';

class PetownerMainMedicalRecordPage extends StatefulWidget {
  const PetownerMainMedicalRecordPage({super.key});

  @override
  State<PetownerMainMedicalRecordPage> createState() =>
      _PetownerMainMedicalRecordPageState();
}

class _PetownerMainMedicalRecordPageState
    extends State<PetownerMainMedicalRecordPage> {
  final PetService _petService = PetService();
  final AuthService _authService = AuthService();
  final MedicalService _medicalService = MedicalService();

  List<Map<String, dynamic>> _pets = [];
  Map<String, List<Map<String, dynamic>>> _allMedicalRecords = {};
  bool _isLoading = true;
  String? _selectedPetId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserPets();
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDetails = await _authService.getUserDetails();
      if (userDetails != null) {
        _userId = userDetails['id'];

        if (_userId != null) {
          final pets = await _petService.getPetsByOwner(_userId!);

          if (mounted) {
            setState(() {
              _pets = pets;

              if (_pets.isNotEmpty) {
                _selectedPetId = _pets.first['id'];
                _loadMedicalRecords(_selectedPetId!);
              } else {
                _isLoading = false;
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar("Failed to load pets: $e");
      }
    }
  }

  Future<void> _loadMedicalRecords(String petId) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (_allMedicalRecords.containsKey(petId)) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final records = await _medicalService.getCompleteMedicalHistory(petId);

      if (mounted) {
        setState(() {
          _allMedicalRecords[petId] = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar("Failed to load medical records: $e");
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        title: const Text(
          'Medical Records',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_pets.isEmpty) {
      return _buildNoPetsView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserPets();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPetSelector(),
            const SizedBox(height: 20),
            _buildPetHeader(),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _selectedPetId != null
                      ? _buildMedicalRecordsList(_selectedPetId!)
                      : const Center(
                        child: Text(
                          'Select a pet to view medical records',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPetsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "No pets found",
            style: TextStyle(fontSize: 20, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            "Add pets to view their medical records",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add a Pet"),
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetSelector() {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          final bool isSelected = pet['id'] == _selectedPetId;
          final petName = pet['name'] ?? 'Unknown';

          final petImage = pet['image_url'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPetId = pet['id'];
              });
              _loadMedicalRecords(pet['id']);
            },
            child: Container(
              width: screenWidth * 0.25,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                color: const Color.fromARGB(255, 55, 65, 70),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.grey[800],
                    backgroundImage:
                        petImage != null && petImage.toString().isNotEmpty
                            ? NetworkImage(petImage)
                            : null,
                    child:
                        (petImage == null || petImage.toString().isEmpty)
                            ? Icon(
                              Icons.pets,
                              size: 24,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.white70,
                            )
                            : null,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    petName,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetHeader() {
    if (_selectedPetId == null) return const SizedBox();

    final selectedPet = _pets.firstWhere((pet) => pet['id'] == _selectedPetId);
    final petName = selectedPet['name'] ?? 'Unknown';
    final species = selectedPet['species'] ?? 'Unknown';
    final breed = selectedPet['breed'] ?? 'Unknown';
    final age = selectedPet['age'] ?? 'Unknown';
    final image = selectedPet['image_url'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.7),
            Colors.blue.shade700.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            backgroundImage:
                image != null && image.toString().isNotEmpty
                    ? NetworkImage(image)
                    : null,
            child:
                (image == null || image.toString().isEmpty)
                    ? const Icon(Icons.pets, size: 35, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$species • $breed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'Age: $age years',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsList(String petId) {
    final records = _allMedicalRecords[petId] ?? [];

    if (records.isEmpty) {
      return _buildNoRecordsView();
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isOwnerRecord = record['source'] == 'owner';
        final diagnosis = record['diagnosis'] ?? 'Unknown';
        final treatment = record['treatment'] ?? 'Not specified';
        final dateString =
            record['created_at'] ?? DateTime.now().toIso8601String();
        final notes = record['notes'] as String? ?? '';
        final imageUrl = record['image_url'] as String?;

        DateTime date;
        try {
          date = DateTime.parse(dateString);
        } catch (e) {
          date = DateTime.now();
        }
        final formattedDate = DateFormat('MMMM d, yyyy').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 50, 60, 70),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                isOwnerRecord
                    ? Border.all(color: Colors.amber.withOpacity(0.7), width: 2)
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isOwnerRecord
                          ? Colors.amber.withOpacity(0.2)
                          : const Color.fromARGB(255, 60, 70, 80),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOwnerRecord
                              ? Icons.upload_file
                              : Icons.medical_services,
                          size: 18,
                          color: isOwnerRecord ? Colors.amber : Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOwnerRecord
                              ? 'Owner-Provided Document'
                              : 'Veterinary Record',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOwnerRecord ? Colors.amber : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isOwnerRecord ? Colors.amber[200] : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwnerRecord && imageUrl != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildImagePreview(imageUrl, isOwnerDocument: true),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecordItem('Diagnosis', diagnosis),
                      const SizedBox(height: 12),
                      _buildRecordItem('Treatment', treatment),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildRecordItem('Additional Notes', notes),
                      ],

                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildImagePreview(imageUrl),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }

  Widget _buildNoRecordsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "No Medical Records Found",
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            "Your pet's medical history will appear here",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String imageUrl, {bool isOwnerDocument = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isOwnerDocument) ...[
          Text(
            'Medical Image',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _viewFullImage(imageUrl),
          child: Container(
            height: isOwnerDocument ? 250 : 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOwnerDocument ? Colors.amber[700]! : Colors.grey[700]!,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: isOwnerDocument ? Colors.amber : AppColors.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image could not be loaded',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Tap to view full image',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isOwnerDocument ? Colors.amber[200] : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  void _viewFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Medical Image',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
