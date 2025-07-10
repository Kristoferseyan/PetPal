import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_main_medical_record_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_medical_record_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_message_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_petActivities_page.dart';
import 'package:petpal/pet-owner-modules/pages/user_profile_customization_page.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/medication_service.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_medications_page.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class PetOwnerHomePage extends StatefulWidget {
  const PetOwnerHomePage({super.key});

  @override
  PetOwnerHomePageState createState() => PetOwnerHomePageState();
}

class PetOwnerHomePageState extends State<PetOwnerHomePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> todayMedications = [];
  List<Map<String, dynamic>> tomorrowMedications = [];

  late TabController _tabController;
  String userName = "User";
  String userId = "";
  String? profileImageUrl;
  bool isLoading = true;
  int todayCompletedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userDetails = await _authService.getUserDetails();
      if (userDetails != null && mounted) {
        setState(() {
          userName = userDetails['full_name'] ?? "User";
          userId = userDetails['id'] ?? "";
          profileImageUrl = userDetails['profile_image'];
        });
      }
      await _loadUpcomingMedications();
      await _updateTodayCompletedCount();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTodayCompletedCount() async {
    if (todayMedications.isEmpty) {
      if (mounted) {
        setState(() {
          todayCompletedCount = 0;
        });
      }

      return;
    }

    int count = 0;
    try {
      for (var med in todayMedications) {
        if (await _medicationService.isMedicationGivenToday(med['id'])) {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          todayCompletedCount = count;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadUpcomingMedications() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final medicationsMap = await _medicationService
            .getUpcomingMedicationsWithPetInfo(user.id);

        if (mounted) {
          setState(() {
            todayMedications = medicationsMap['today'] ?? [];
            tomorrowMedications = medicationsMap['tomorrow'] ?? [];
          });
        }
        await _updateTodayCompletedCount();
      } catch (e) {}
    }
  }

  void refreshData() {
    _loadUpcomingMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      body: SafeArea(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
                : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            _buildDashboardSummary(),
                            _buildTabBar(),
                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMedicationsList(
                              todayMedications,
                              isToday: true,
                            ),
                            _buildMedicationsList(
                              tomorrowMedications,
                              isToday: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: AppColors.primary,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 10,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.medication, color: Colors.white),
            backgroundColor: AppColors.secondary,
            label: 'Medications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationsPage(),
                ),
              ).then((_) => _loadUserData());
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.medical_information, color: Colors.white),
            backgroundColor: AppColors.secondary,
            label: 'Medical Records',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PetownerMainMedicalRecordPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => UserProfileCustomizationPage(
                              isFirstTimeSetup: false,
                            ),
                      ),
                    ).then((_) => _loadUserData());
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!)
                            : null,
                    child:
                        profileImageUrl == null || profileImageUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello,",
                    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(234, 50, 70, 79),
            Color.fromARGB(255, 79, 50, 64),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Progress",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$todayCompletedCount of ${todayMedications.length} medications given",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.white24,
                      strokeWidth: 6,
                    ),
                    CircularProgressIndicator(
                      value:
                          todayMedications.isEmpty
                              ? 0.0
                              : todayCompletedCount / todayMedications.length,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        todayMedications.isEmpty
                            ? Colors.white
                            : todayCompletedCount / todayMedications.length >=
                                1.0
                            ? Colors.green[300]!
                            : Colors.white,
                      ),
                      strokeWidth: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 50, 60, 65),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerHeight: 0,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.today),
                const SizedBox(width: 8),
                const Text("Today"),
                if (todayMedications.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${todayMedications.length}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                const Text("Tomorrow"),
                if (tomorrowMedications.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${tomorrowMedications.length}",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList(
    List<Map<String, dynamic>> medications, {
    required bool isToday,
  }) {
    return medications.isEmpty
        ? _buildEmptyState(isToday)
        : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
          itemCount: medications.length + 1,
          itemBuilder: (context, index) {
            if (index == medications.length) {
              return Container(margin: const EdgeInsets.only(top: 16));
            }
            return _buildMedicationCard(medications[index], isToday);
          },
        );
  }

  Widget _buildEmptyState(bool isToday) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isToday ? "All clear for today!" : "Nothing scheduled for tomorrow",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? "No medications scheduled for today. You can click the medications icon to view all medications."
                : "No medications scheduled for tomorrow. You can click the medications icon to view all medications.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication, bool isToday) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      color: const Color.fromARGB(234, 50, 70, 79),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'pet_${medication['pet_name']}_${medication['id']}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          medication['pet_image'] != null &&
                                  medication['pet_image'].isNotEmpty
                              ? Image.network(
                                medication['pet_image'],
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.pets,
                                      size: 30,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
                              )
                              : const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 30,
                                  color: Colors.white70,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication['pet_name'] ?? 'Unknown Pet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medication['medication_name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  FutureBuilder<bool>(
                    future: _medicationService.isMedicationGivenToday(
                      medication['id'],
                    ),
                    builder: (context, snapshot) {
                      final bool isGiven = snapshot.data ?? false;
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              isGiven
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          isGiven ? "Given" : "Due",
                          style: TextStyle(
                            color:
                                isGiven ? Colors.green[100] : Colors.red[100],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.medical_information,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PetOwnerMedicalRecordsPage(
                              petId: medication['pet_id'],
                              petName: medication['pet_name'] ?? 'Unknown Pet',
                            ),
                      ),
                    );
                  },
                  tooltip: 'View Medical Records',
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
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
                            Icons.medical_information,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Dosage: ${medication['dosage']}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (medication['notes'] != null &&
                          medication['notes'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notes,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Note: ${medication['notes']}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
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
                if (isToday)
                  FutureBuilder<bool>(
                    future: _medicationService.isMedicationGivenToday(
                      medication['id'],
                    ),
                    builder: (context, snapshot) {
                      final bool isGiven = snapshot.data ?? false;
                      return Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: isGiven,
                          onChanged: (value) async {
                            if (value == true && !isGiven) {
                              try {
                                await _medicationService.markMedicationAsGiven(
                                  medication['id'],
                                );
                                await _updateTodayCompletedCount();
                                setState(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: ${e.toString()}"),
                                  ),
                                );
                              }
                            }
                          },
                          fillColor: MaterialStateProperty.all(Colors.white),
                          checkColor: const Color.fromARGB(255, 79, 50, 64),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
