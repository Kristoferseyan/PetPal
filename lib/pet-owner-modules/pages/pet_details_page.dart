import 'package:flutter/material.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:barcode_widget/barcode_widget.dart';

class PetDetailsPage extends StatefulWidget {
  final String petId;

  const PetDetailsPage({super.key, required this.petId});

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  String? petName;
  String? breed;
  String? species;
  String? age;
  String? weight;
  String? gender;
  String? imageUrl;
  List<Map<String, dynamic>> medicationHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPetDetails();
  }

  Future<void> _fetchPetDetails() async {
    try {
      final petData = await PetService().getPet(widget.petId);
      final medicalHistory = await MedicalService().getMedicalHistory(
        widget.petId,
      );

      setState(() {
        petName = petData['name'];
        breed = petData['breed'];
        species = petData['species'];
        age = petData['age'].toString();
        weight = petData['weight'].toString();
        gender = petData['gender'];
        imageUrl = petData['imageUrl'];
        medicationHistory = medicalHistory;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch pet details")));
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 37, 45, 50),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: const Text(
            'Pet Details',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color.fromARGB(255, 44, 59, 70),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Pet Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 44, 59, 70),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildPetInfo(),
            const SizedBox(height: 24),
            _buildMedicationHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildPetInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 31, 35, 35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                        imageUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.grey,
                          );
                        },
                      )
                      : Image.asset(
                        'assets/images/placeholder.jpg',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Text(
                    petName ?? 'Loading...',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPetDetailText('Breed: ${breed ?? 'Loading...'}'),
                  _buildPetDetailText('Age: ${age ?? 'Loading...'} years'),
                  _buildPetDetailText('Weight: ${weight ?? 'Loading...'} kg'),
                  _buildPetDetailText('Gender: ${gender ?? 'Loading...'}'),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 31, 35, 35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BarcodeWidget(
                    data:
                        'Pet: ${petName ?? 'Loading...'}\nBreed: ${breed ?? 'Loading...'}\nAge: ${age ?? 'Loading...'}\nWeight: ${weight ?? 'Loading...'}',
                    barcode: Barcode.qrCode(),
                    width: 150,
                    height: 150,
                    color: Colors.white,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetDetailText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.primary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildMedicationHistory() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 340,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 31, 35, 35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          medicationHistory.isEmpty
              ? Center(
                child: Text(
                  'No medical records yet',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
              : Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        medicationHistory.map((record) {
                          return Card(
                            color: const Color.fromARGB(255, 31, 35, 35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              title: Text(
                                record['diagnosis'] ?? 'Unknown Diagnosis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              subtitle: Text(
                                'Treatment: ${record['treatment']} - Date: ${record['date']}',
                                style: TextStyle(
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
