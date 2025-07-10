import 'package:flutter/material.dart';
import 'package:petpal/services/medication_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/vet-modules/widgets/add_medication_form.dart';
import 'package:intl/intl.dart';

class MedicationManagementPage extends StatefulWidget {
  final String? initialPetId;

  const MedicationManagementPage({super.key, this.initialPetId});

  @override
  _MedicationManagementPageState createState() =>
      _MedicationManagementPageState();
}

class _MedicationManagementPageState extends State<MedicationManagementPage> {
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> pets = [];
  List<Map<String, dynamic>> recentPets = [];
  List<Map<String, dynamic>> petOwners = [];

  String? selectedPetId;
  Map<String, dynamic>? selectedPet;
  bool isLoading = true;
  bool initialLoadComplete = false;

  final PetService _petService = PetService();
  final MedicationService _medicationService = MedicationService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _loadPetOwners();

      if (widget.initialPetId != null) {
        await _loadSpecificPet(widget.initialPetId!);
      }

      setState(() {
        initialLoadComplete = true;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to initialize", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPetOwners() async {
    try {
      final owners = await _authService.getPetOwners();
      if (mounted) {
        setState(() {
          petOwners = owners;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load pet owners", isError: true);
      }
    }
  }

  Future<void> _loadSpecificPet(String petId) async {
    try {
      final pet = await _petService.getPet(petId);
      if (pet != null && mounted) {
        setState(() {
          selectedPetId = pet['id'];
          selectedPet = pet;
        });
        await _loadMedications();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load pet information", isError: true);
      }
    }
  }

  Future<void> _loadPetsForOwner(String ownerId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final ownerPets = await _petService.getPets(ownerId);

      if (mounted) {
        setState(() {
          pets = ownerPets;
          isLoading = false;
        });
      }

      _showPetSelectionDialog();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showSnackBar("Failed to load owner's pets", isError: true);
      }
    }
  }

  void _showOwnerSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PetOwnerSearchDialog(
          petOwners: petOwners,
          onOwnerSelected: (ownerId, _) {
            Navigator.pop(context);
            _loadPetsForOwner(ownerId);
          },
        );
      },
    );
  }

  void _showPetSelectionDialog() {
    if (pets.isEmpty) {
      _showSnackBar("No pets found for this owner", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 37, 45, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select a Pet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            pet['image_url'] != null &&
                                    pet['image_url'].toString().isNotEmpty
                                ? NetworkImage(pet['image_url'])
                                : null,
                        backgroundColor: Colors.grey[800],
                        child:
                            pet['image_url'] == null ||
                                    pet['image_url'].toString().isEmpty
                                ? const Icon(Icons.pets, color: Colors.white70)
                                : null,
                      ),
                      title: Text(
                        pet['name'] ?? 'Unnamed Pet',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "${pet['species'] ?? 'Unknown'} • ${pet['breed'] ?? 'Unknown'}",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedPetId = pet['id'];
                          selectedPet = pet;
                        });
                        _loadMedications();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMedications() async {
    if (selectedPetId != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final List<Map<String, dynamic>> fetchedMedications =
            await _medicationService.getMedications(selectedPetId!);

        if (mounted) {
          setState(() {
            medications = fetchedMedications;
          });
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar("Failed to load medications", isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void _addMedication() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 37, 45, 50),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add New Medication",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: AddMedicationForm(
                  petId: selectedPetId!,
                  onMedicationAdded: (success) {
                    Navigator.pop(context);
                    if (success) {
                      _loadMedications();
                      _showSnackBar("Medication added successfully");
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMedication(String medicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 50, 60, 65),
            title: const Text(
              "Delete Medication",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to delete this medication? This action cannot be undone.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _medicationService.deleteMedication(medicationId);
        _loadMedications();
        _showSnackBar("Medication deleted successfully");
      } catch (e) {
        _showSnackBar("Failed to delete medication", isError: true);
      }
    }
  }

  void _showMedicationDetails(Map<String, dynamic> medication) {
    DateTime? startDate =
        medication['start_date'] != null
            ? DateTime.parse(medication['start_date'])
            : null;
    DateTime? endDate =
        medication['end_date'] != null
            ? DateTime.parse(medication['end_date'])
            : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 50, 60, 65),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      medication['medication_name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                _buildDetailRow("Dosage:", medication['dosage']),
                _buildDetailRow("Frequency:", medication['frequency']),
                _buildDetailRow("Start Date:", _formatDate(startDate)),
                _buildDetailRow("End Date:", _formatDate(endDate)),
                if (medication['notes'] != null &&
                    medication['notes'].toString().isNotEmpty)
                  _buildDetailRow("Notes:", medication['notes']),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        "Edit",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMedication(medication['id']);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Not specified",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Not Set";
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Medication Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedPetId != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _loadMedications,
                      tooltip: "Refresh medications",
                    ),
                ],
              ),
              const SizedBox(height: 16),

              selectedPet != null
                  ? _buildSelectedPetCard()
                  : _buildPetSelectionButton(),

              const SizedBox(height: 16),

              if (selectedPet == null && recentPets.isNotEmpty)
                _buildRecentPetsSection(),

              if (selectedPet != null) const SizedBox(height: 16),

              if (selectedPet != null)
                Expanded(
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                          : medications.isEmpty
                          ? _buildEmptyMedicationsState()
                          : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: medications.length,
                            itemBuilder: (context, index) {
                              final medication = medications[index];
                              return _buildMedicationCard(medication);
                            },
                          ),
                ),

              if (selectedPet == null &&
                  (recentPets.isEmpty || !initialLoadComplete))
                Expanded(
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                          : _buildInitialEmptyState(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          selectedPetId != null
              ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: _addMedication,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildSelectedPetCard() {
    return Card(
      color: const Color.fromARGB(255, 50, 60, 65),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: _showOwnerSearchDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage:
                    selectedPet!['image_url'] != null &&
                            selectedPet!['image_url'].toString().isNotEmpty
                        ? NetworkImage(selectedPet!['image_url'])
                        : null,
                backgroundColor: Colors.grey[800],
                child:
                    selectedPet!['image_url'] == null ||
                            selectedPet!['image_url'].toString().isEmpty
                        ? const Icon(Icons.pets, color: Colors.white70)
                        : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPet!['name'] ?? "Unnamed Pet",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${selectedPet!['species'] ?? 'Unknown'} • ${selectedPet!['breed'] ?? 'Unknown'}",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Change",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetSelectionButton() {
    return ElevatedButton.icon(
      onPressed: _showOwnerSearchDialog,
      icon: const Icon(Icons.pets, color: Colors.white),
      label: const Text("Select a Pet", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildRecentPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            "Recently Accessed Pets",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentPets.length,
            itemBuilder: (context, index) {
              final pet = recentPets[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPetId = pet['id'];
                      selectedPet = pet;
                    });
                    _loadMedications();
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage:
                            pet['image_url'] != null &&
                                    pet['image_url'].toString().isNotEmpty
                                ? NetworkImage(pet['image_url'])
                                : null,
                        backgroundColor: Colors.grey[800],
                        child:
                            pet['image_url'] == null ||
                                    pet['image_url'].toString().isEmpty
                                ? const Icon(
                                  Icons.pets,
                                  size: 24,
                                  color: Colors.white70,
                                )
                                : null,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        pet['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Text(
                        pet['species'] ?? 'Unknown',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_outlined, size: 80, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            "No Pet Selected",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please select a pet to manage medications",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              "Select a Pet",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _showOwnerSearchDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMedicationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 80,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No medications found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add medications using the + button",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Add First Medication",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _addMedication,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    DateTime? startDate =
        medication['start_date'] != null
            ? DateTime.parse(medication['start_date'])
            : null;
    DateTime? endDate =
        medication['end_date'] != null
            ? DateTime.parse(medication['end_date'])
            : null;

    final now = DateTime.now();
    final isActive =
        (startDate == null ||
            startDate.isBefore(now) ||
            startDate.isAtSameMomentAs(now)) &&
        (endDate == null ||
            endDate.isAfter(now) ||
            endDate.isAtSameMomentAs(now));
    return Card(
      color: const Color.fromARGB(255, 50, 60, 65),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showMedicationDetails(medication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                medication['medication_name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.timeline,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Dosage: ${medication['dosage']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Frequency: ${medication['frequency']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? "Active" : "Inactive",
                          style: TextStyle(
                            color:
                                isActive ? Colors.green[300] : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_formatDate(startDate)} - ${endDate != null ? _formatDate(endDate) : 'Ongoing'}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (medication['notes'] != null &&
                  medication['notes'].toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medication['notes'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetOwnerSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> petOwners;
  final Function(String, String) onOwnerSelected;

  const _PetOwnerSearchDialog({
    Key? key,
    required this.petOwners,
    required this.onOwnerSelected,
  }) : super(key: key);

  @override
  _PetOwnerSearchDialogState createState() => _PetOwnerSearchDialogState();
}

class _PetOwnerSearchDialogState extends State<_PetOwnerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredOwners = [];

  @override
  void initState() {
    super.initState();
    _filteredOwners = List.from(widget.petOwners);
  }

  void _filterOwners(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredOwners = List.from(widget.petOwners);
      });
      return;
    }

    final queryLower = query.toLowerCase();
    setState(() {
      _filteredOwners =
          widget.petOwners.where((owner) {
            final name = (owner['full_name'] ?? '').toString().toLowerCase();
            final email = (owner['email'] ?? '').toString().toLowerCase();

            return name.contains(queryLower) || email.contains(queryLower);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Pet Owner",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by name or email",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color.fromARGB(255, 31, 38, 42),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterOwners,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child:
                _filteredOwners.isEmpty
                    ? _buildEmptySearchResults()
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredOwners.length,
                      itemBuilder: (context, index) {
                        final owner = _filteredOwners[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            child: Text(
                              _getInitials(owner['full_name'] ?? ''),
                              style: TextStyle(color: Colors.green[200]),
                            ),
                          ),
                          title: Text(
                            owner['full_name'] ?? 'Unnamed Owner',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            owner['email'] ?? 'No Email',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          onTap:
                              () => widget.onOwnerSelected(
                                owner['id'],
                                owner['full_name'] ?? 'Unnamed Owner',
                              ),
                        );
                      },
                    ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              "No owners found",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';

    final nameParts = fullName.split(' ');
    if (nameParts.length >= 2) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }
}
