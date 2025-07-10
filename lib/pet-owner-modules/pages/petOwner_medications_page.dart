import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/medication_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';

class MedicationsPage extends StatefulWidget {
  const MedicationsPage({super.key});

  @override
  _MedicationsPageState createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  late Future<List<Map<String, dynamic>>> medications;
  String ownerId = '';
  String selectedPetId = '';
  List<String> petIds = [];
  List<String> petNames = [];
  List<Map<String, dynamic>> petInfo = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    await _loadUserData();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userDetails = await AuthService().getUserDetails();
      if (userDetails != null) {
        ownerId = userDetails['id'] ?? '';

        petInfo = await PetService().getPetsDetailsByOwnerId(ownerId);

        petIds = petInfo.map<String>((pet) => pet['id'] as String).toList();
        petNames = petInfo.map<String>((pet) => pet['name'] as String).toList();

        if (petIds.isNotEmpty) {
          selectedPetId = 'all';
          medications = _fetchMedications(selectedPetId);
        } else {
          medications = Future.value([]);
        }
      }
    } catch (e) {
      medications = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMedications(String petId) async {
    if (petId == 'all') {
      List<Map<String, dynamic>> allMedications = [];
      for (String id in petIds) {
        final medicationsList = await MedicationService().getMedications(id);

        for (var med in medicationsList) {
          final petIndex = petIds.indexOf(id);
          if (petIndex >= 0 && petIndex < petNames.length) {
            med['pet_name'] = petNames[petIndex];

            final pet = petInfo.firstWhere(
              (p) => p['id'] == id,
              orElse: () => {},
            );
            med['pet_species'] = pet['species'] ?? 'Unknown';
            med['pet_breed'] = pet['breed'] ?? '';
          }
        }

        allMedications.addAll(medicationsList);
      }

      allMedications.sort((a, b) {
        DateTime dateA = _parseDate(a['start_date']) ?? DateTime.now();
        DateTime dateB = _parseDate(b['start_date']) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return allMedications;
    } else {
      final medicationsList = await MedicationService().getMedications(petId);

      for (var med in medicationsList) {
        final petIndex = petIds.indexOf(petId);
        if (petIndex >= 0 && petIndex < petNames.length) {
          med['pet_name'] = petNames[petIndex];
        }
      }

      medicationsList.sort((a, b) {
        DateTime dateA = _parseDate(a['start_date']) ?? DateTime.now();
        DateTime dateB = _parseDate(b['start_date']) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return medicationsList;
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  void _showMedicationDetails(Map<String, dynamic> medication) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 37, 45, 50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: MedicationDetailBottomSheet(medication: medication),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Pet Medications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                medications = _fetchMedications(selectedPetId);
              });
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    medications = _fetchMedications(selectedPetId);
                  });
                },
                child: _buildBody(),
              ),
    );
  }

  Widget _buildBody() {
    if (petIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No pets found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add a pet in your profile to track medications",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPetSelector(),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: medications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.medication_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedPetId == 'all'
                            ? "No medications found for any pets"
                            : "No medications found for this pet",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final medicationList = snapshot.data!;
              return _buildMedicationList(medicationList);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 54, 60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Pet",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPetFilterChip(
                  isSelected: selectedPetId == 'all',
                  label: 'All Pets',
                  onTap: () {
                    setState(() {
                      selectedPetId = 'all';
                      medications = _fetchMedications(selectedPetId);
                    });
                  },
                  icon: Icons.pets,
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  petIds.length,
                  (index) => _buildPetFilterChip(
                    isSelected: selectedPetId == petIds[index],
                    label: petNames[index],
                    onTap: () {
                      setState(() {
                        selectedPetId = petIds[index];
                        medications = _fetchMedications(selectedPetId);
                      });
                    },
                    icon: Icons.pets,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetFilterChip({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList(List<Map<String, dynamic>> medications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final medication = medications[index];
        return _buildMedicationCard(medication);
      },
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final startDate = _parseDate(medication['start_date']);
    final endDate = _parseDate(medication['end_date']);
    final now = DateTime.now();

    bool isActive = true;
    if (endDate != null) {
      isActive = endDate.isAfter(now);
    }

    final petName = medication['pet_name'] ?? 'Unknown Pet';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 31, 38, 43),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: isActive ? Colors.green[700] : Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.history,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Active Medication' : 'Past Medication',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showMedicationDetails(medication),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication['medication_name'] ??
                                  'Unknown Medication',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (selectedPetId == 'all')
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pets,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    petName,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showMedicationDetails(medication),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.medical_services,
                        label: 'Dosage',
                        value: medication['dosage'] ?? 'N/A',
                      ),
                      _buildInfoItem(
                        icon: Icons.schedule,
                        label: 'Frequency',
                        value: medication['frequency'] ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        label: 'Start Date',
                        value:
                            startDate != null
                                ? DateFormat('MMM d, yyyy').format(startDate)
                                : 'N/A',
                      ),
                      _buildInfoItem(
                        icon: Icons.event_available,
                        label: 'End Date',
                        value:
                            endDate != null
                                ? DateFormat('MMM d, yyyy').format(endDate)
                                : 'Ongoing',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> medication;

  const MedicationDetailBottomSheet({Key? key, required this.medication})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startDate = _parseDate(medication['start_date']);
    final endDate = _parseDate(medication['end_date']);
    final now = DateTime.now();

    bool isActive = true;
    if (endDate != null) {
      isActive = endDate.isAfter(now);
    }

    String timeDescription;
    if (endDate != null) {
      final difference = endDate.difference(now).inDays;
      if (difference > 0) {
        timeDescription = '$difference days remaining';
      } else if (difference == 0) {
        timeDescription = 'Last day today';
      } else {
        timeDescription = 'Completed ${-difference} days ago';
      }
    } else {
      timeDescription = 'Ongoing medication';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.green[700] : Colors.grey[700],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: Icon(
                  Icons.medication,
                  color: isActive ? Colors.green[700] : Colors.grey[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['medication_name'] ?? 'Unknown Medication',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.history,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Active Medication' : 'Past Medication',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Colors.green[700]!.withOpacity(0.2)
                            : Colors.grey[700]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green[700]! : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.calendar_today : Icons.event_busy,
                        color: isActive ? Colors.green[400] : Colors.grey[400],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeDescription,
                            style: TextStyle(
                              color:
                                  isActive
                                      ? Colors.green[400]
                                      : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (startDate != null && endDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (medication['pet_name'] != null)
                  _buildDetailSection('Pet Information', [
                    _buildDetailItem('Pet Name', medication['pet_name']),
                    if (medication['pet_species'] != null)
                      _buildDetailItem('Species', medication['pet_species']),
                    if (medication['pet_breed'] != null &&
                        medication['pet_breed'] != '')
                      _buildDetailItem('Breed', medication['pet_breed']),
                  ]),

                _buildDetailSection('Medication Details', [
                  _buildDetailItem(
                    'Medication Name',
                    medication['medication_name'],
                  ),
                  _buildDetailItem('Dosage', medication['dosage']),
                  _buildDetailItem('Frequency', medication['frequency']),
                  _buildDetailItem(
                    'Administration Route',
                    medication['route'] ?? 'N/A',
                  ),
                ]),

                _buildDetailSection('Schedule', [
                  _buildDetailItem(
                    'Start Date',
                    startDate != null
                        ? DateFormat('MMMM d, y').format(startDate)
                        : 'Not specified',
                  ),
                  _buildDetailItem(
                    'End Date',
                    endDate != null
                        ? DateFormat('MMMM d, y').format(endDate)
                        : 'Ongoing/Not specified',
                  ),
                  _buildDetailItem(
                    'Duration',
                    medication['duration'] ?? 'Not specified',
                  ),
                ]),

                if (medication['notes'] != null && medication['notes'] != '')
                  _buildDetailSection('Additional Information', [
                    _buildDetailItem('Notes', medication['notes']),
                  ]),

                _buildDetailSection('Prescribing Information', [
                  _buildDetailItem(
                    'Prescribed By',
                    medication['prescriber_name'] ?? 'N/A',
                  ),
                  _buildDetailItem(
                    'Prescribed On',
                    medication['prescribed_date'] != null
                        ? DateFormat(
                          'MMMM d, y',
                        ).format(_parseDate(medication['prescribed_date'])!)
                        : 'N/A',
                  ),
                ]),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Set Reminder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 54, 60),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
