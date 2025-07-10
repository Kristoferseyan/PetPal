import 'dart:io';
import 'package:flutter/material.dart';
import 'package:petpal/services/cloudinary.service.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/vet-modules/pages/health-record-widgets/medical_record_form.dart';
import 'package:petpal/vet-modules/pages/health-record-widgets/medical_records_list.dart';
import 'package:petpal/vet-modules/pages/health-record-widgets/pet_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/utils/colors.dart';

class HealthRecordsPage extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final String? initialPetId;

  const HealthRecordsPage({
    Key? key,
    required this.ownerId,
    required this.ownerName,
    this.initialPetId,
  }) : super(key: key);

  @override
  State<HealthRecordsPage> createState() => _HealthRecordsPageState();
}

class _HealthRecordsPageState extends State<HealthRecordsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> pets = [];
  List<Map<String, dynamic>> medicalRecords = [];
  String selectedPetId = '';
  String selectedPetName = '';
  bool isLoading = true;
  bool _initialSelectionDone = false;

  MedicalService _medicalService = MedicalService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final PetService _petService = PetService();

  Future<void> _loadPets() async {
    try {
      final fetchedPets = await _petService.getPetsByOwner(widget.ownerId);

      if (fetchedPets.isNotEmpty) {}

      final transformedPets =
          fetchedPets.map<Map<String, dynamic>>((pet) {
            return {
              'id': pet['id'],
              'name': pet['name'] ?? 'Unnamed Pet',
              'photo_url': pet['image_url'] ?? pet['imageUrl'],
              'species': pet['species'] ?? 'Unknown',
              'breed': pet['breed'],
            };
          }).toList();

      setState(() {
        pets = transformedPets;
        isLoading = false;

        if (pets.isNotEmpty) {
          selectedPetId = pets[0]['id'];
          selectedPetName = pets[0]['name'];
          _loadMedicalRecords(selectedPetId);
        }
      });

      _handleInitialPetSelection(pets);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMedicalRecords(String petId) async {
    try {
      setState(() => isLoading = true);

      final records = await _medicalService.getCompleteMedicalHistory(petId);

      setState(() {
        medicalRecords = records;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _handleInitialPetSelection(List<Map<String, dynamic>> pets) {
    if (_initialSelectionDone || widget.initialPetId == null) return;
    _initialSelectionDone = true;

    for (var pet in pets) {
      if (pet['id'] == widget.initialPetId) {
        setState(() {
          selectedPetId = pet['id'];
          selectedPetName = pet['name'] ?? 'Unnamed Pet';
        });
        _loadMedicalRecords(selectedPetId);
        break;
      }
    }
  }

  void _onPetSelected(String petId, String petName) {
    setState(() {
      selectedPetId = petId;
      selectedPetName = petName;
    });
    _loadMedicalRecords(petId);
  }

  void _onRecordSaved() {
    _loadMedicalRecords(selectedPetId);
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Health Records',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${widget.ownerName}'s Pets",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Medical Records'),
            Tab(text: 'Add Record'),
            Tab(text: 'Archives'),
          ],
        ),
      ),
      body:
          isLoading && pets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  PetSelector(
                    pets: pets,
                    selectedPetId: selectedPetId,
                    onPetSelected: _onPetSelected,
                  ),
                  if (selectedPetId.isNotEmpty)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          MedicalRecordsList(
                            petId: selectedPetId,
                            medicalRecords: medicalRecords,
                            onRecordUpdated:
                                () => _loadMedicalRecords(selectedPetId),
                            medicalService: _medicalService,
                          ),
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: MedicalRecordForm(
                                petId: selectedPetId,
                                petName: selectedPetName,
                                onRecordSaved: _onRecordSaved,
                              ),
                            ),
                          ),
                          ArchivedRecordsList(
                            petId: selectedPetId,
                            onRecordRestored:
                                () => _loadMedicalRecords(selectedPetId),
                            medicalService: _medicalService,
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text(
                              pets.isEmpty
                                  ? 'No pets found for this owner'
                                  : 'Select a pet to view or add health records',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      floatingActionButton:
          selectedPetId.isNotEmpty && _tabController.index == 0
              ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
