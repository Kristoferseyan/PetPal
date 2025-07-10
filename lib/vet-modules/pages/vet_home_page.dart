import 'package:flutter/material.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:petpal/vet-modules/pages/vet_mainHealth_records.dart';
import 'package:petpal/vet-modules/pages/vet_pet_owners.dart';
import 'package:petpal/vet-modules/pages/vet_scanQr_page.dart';
import 'package:petpal/vet-modules/pages/vet_appointments_page.dart';
import 'package:intl/intl.dart';
import 'package:petpal/vet-modules/pages/vet_set_appointment_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  _StaffPageState createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  String userName = "Clinic Staff";
  String clinicName = "PetPal Veterinary Clinic";
  bool isLoading = true;

  final AuthService _authService = AuthService();
  final AppointmentService _appointmentService = AppointmentService();
  List<Map<String, dynamic>> _todaysAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _loadTodaysAppointments();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userDetails = await _authService.getUserDetails();
      await _loadTodaysAppointments();

      if (mounted) {
        setState(() {
          userName = userDetails?['full_name'] ?? "Clinic Staff";
          clinicName =
              userDetails?['clinic_name'] ?? "PetPal Veterinary Clinic";
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodaysAppointments() async {
    try {
      final weeklyAppointments =
          await _appointmentService.getAppointmentsForThisWeek();

      if (mounted) {
        setState(() {
          final today = DateTime.now();
          final todayFormatted =
              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

          _todaysAppointments =
              weeklyAppointments
                  .where((apt) => apt['appointmentDate'] == todayFormatted)
                  .toList();

          _todaysAppointments.sort((a, b) {
            final timeA = a['appointmentTime'];
            final timeB = b['appointmentTime'];
            return timeA.compareTo(timeB);
          });

          if (_todaysAppointments.isEmpty) {
            final tomorrow = DateTime.now().add(const Duration(days: 1));
            final tomorrowFormatted =
                "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

            _todaysAppointments =
                weeklyAppointments
                    .where((apt) => apt['appointmentDate'] == tomorrowFormatted)
                    .toList();
          }
        });
      }
    } catch (e) {}
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VetScanQRPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _showPetDetailsDialog(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    final EdgeInsets safePadding = MediaQuery.of(context).padding;
    final bool isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : RefreshIndicator(
                onRefresh: _loadStaffData,
                color: AppColors.primary,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double horizontalPadding = screenWidth * 0.05;
                    final double topPadding = safePadding.top + 16;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            SizedBox(height: screenHeight * 0.03),
                            _buildClinicSummary(context),
                            SizedBox(height: screenHeight * 0.03),
                            _buildQuickActions(context),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
      child: Row(
        children: [
          CircleAvatar(
            radius: screenWidth * 0.06,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $userName",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  clinicName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[400],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppColors.primary,
              size: screenWidth * 0.06,
            ),
            onPressed: _loadStaffData,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicSummary(BuildContext context) {
    final today = DateTime.now();
    final todayFormatted =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    bool isShowingToday =
        _todaysAppointments.isNotEmpty &&
        _todaysAppointments.first['appointmentDate'] == todayFormatted;

    String dateText = isShowingToday ? "Appointments" : "Appointments";

    final Size screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.04;
    final double iconSize = screenSize.width * 0.05;
    final double contentPadding = screenSize.width * 0.04;
    final double listHeight = screenSize.height * 0.2;

    return Container(
      padding: EdgeInsets.all(contentPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(234, 50, 70, 79),
            Color.fromARGB(255, 79, 50, 64),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: screenSize.width * 0.02),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_month,
                  size: iconSize * 0.8,
                  color: Colors.white,
                ),
                label: Text(
                  "View All",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize * 0.9,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffAppointmentPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.03,
                    vertical: screenSize.height * 0.005,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: TextStyle(color: Colors.white70, fontSize: fontSize * 0.9),
          ),
          SizedBox(height: screenSize.height * 0.02),
          if (_todaysAppointments.isEmpty)
            _buildNoAppointmentsView(context)
          else
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount:
                    _todaysAppointments.length > 3
                        ? 3
                        : _todaysAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = _todaysAppointments[index];
                  final appointmentType =
                      appointment['appointmentType'] ?? 'Check-up';

                  String formattedTime = appointment['appointmentTime'];
                  try {
                    final timeParts = formattedTime.split(':');
                    final hour = int.parse(timeParts[0]);
                    final minute = int.parse(timeParts[1]);

                    final period = hour >= 12 ? 'PM' : 'AM';
                    final hour12 =
                        hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                    formattedTime =
                        '${hour12.toString()}:${minute.toString().padLeft(2, '0')} $period';
                  } catch (e) {}

                  bool isMissed = false;
                  try {
                    final now = DateTime.now();
                    final today =
                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                    if (appointment['appointmentDate'] == today) {
                      final currentTime = TimeOfDay.now();
                      final currentMinutes =
                          currentTime.hour * 60 + currentTime.minute;

                      final timeParts = appointment['appointmentTime'].split(
                        ':',
                      );
                      final appointmentHour = int.parse(timeParts[0]);
                      final appointmentMinute = int.parse(timeParts[1]);
                      final appointmentMinutes =
                          appointmentHour * 60 + appointmentMinute;

                      isMissed = currentMinutes > appointmentMinutes;
                    }
                  } catch (e) {}

                  return Container(
                    margin: EdgeInsets.only(bottom: screenSize.height * 0.01),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.03,
                      vertical: screenSize.height * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isMissed
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isMissed
                                ? Colors.redAccent.withOpacity(0.3)
                                : Colors.white12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: screenSize.height * 0.035,
                          decoration: BoxDecoration(
                            color:
                                isMissed
                                    ? Colors.redAccent
                                    : _getAppointmentTypeColor(appointmentType),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.025),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      appointment['petName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isMissed
                                                ? Colors.white70
                                                : Colors.white,
                                        fontSize: fontSize * 0.95,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isMissed)
                                        Container(
                                          margin: EdgeInsets.only(right: 8),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.redAccent
                                                  .withOpacity(0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            "Missed",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w500,
                                              fontSize: fontSize * 0.65,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          color:
                                              isMissed
                                                  ? Colors.white60
                                                  : Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: fontSize * 0.9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: screenSize.height * 0.005),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      appointment['species'] ?? 'Pet',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.8,
                                        color: Colors.grey[300],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenSize.width * 0.02,
                                      vertical: screenSize.height * 0.002,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getAppointmentTypeColor(
                                        appointmentType,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      appointmentType,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSize * 0.7,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_todaysAppointments.length > 3)
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: screenSize.height * 0.01),
                child: Text(
                  "+ ${_todaysAppointments.length - 3} more appointments",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: fontSize * 0.8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoAppointmentsView(BuildContext context) {
    final double containerHeight = MediaQuery.of(context).size.height * 0.12;
    final double iconSize = MediaQuery.of(context).size.width * 0.08;
    final double fontSize = MediaQuery.of(context).size.width * 0.035;

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.white54, size: iconSize),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              "No upcoming appointments",
              style: TextStyle(color: Colors.white70, fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAppointmentTypeColor(String type) {
    switch (type) {
      case 'Check-up':
        return Colors.teal;
      case 'Vaccination':
        return Colors.blueAccent;
      case 'Operation':
        return Colors.redAccent;
      case 'Grooming':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double titleFontSize = screenSize.width * 0.055;
    final bool isLandscape = screenSize.width > screenSize.height;
    final int crossAxisCount = isLandscape ? 3 : 2;
    final double cardAspectRatio = isLandscape ? 1.5 : 1.2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        GridView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardAspectRatio,
            crossAxisSpacing: screenSize.width * 0.03,
            mainAxisSpacing: screenSize.height * 0.015,
          ),
          children: [
            _buildResponsiveDashboardCard(
              context: context,
              title: "Scan Pet QR",
              icon: Icons.qr_code_scanner,
              onTap: _scanQRCode,
              color: const Color.fromARGB(255, 79, 50, 64),
            ),
            _buildResponsiveDashboardCard(
              context: context,
              title: "Appointment",
              icon: Icons.calendar_month_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetSetAppointmentPage(),
                  ),
                );
              },
              color: const Color.fromARGB(255, 50, 64, 79),
            ),
            _buildResponsiveDashboardCard(
              context: context,
              title: "Medical Records",
              icon: Icons.medical_services,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VetMainhealthRecords(),
                  ),
                );
              },
              color: const Color.fromARGB(255, 64, 79, 50),
            ),
            _buildResponsiveDashboardCard(
              context: context,
              title: "Pet Owners",
              icon: Icons.health_and_safety,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VetPetOwnerPage(),
                    ),
                  ),
              color: const Color.fromARGB(255, 76, 50, 79),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsiveDashboardCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    final Size screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.07;
    final double fontSize = screenSize.width * 0.035;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      color: color,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.03),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: Colors.white),
              SizedBox(height: screenSize.height * 0.01),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPetDetailsDialog(Map<String, dynamic> petData) {
    final Size screenSize = MediaQuery.of(context).size;
    final double dialogWidth = screenSize.width * 0.9;
    final double dialogMaxHeight = screenSize.height * 0.7;
    final double fontSize = screenSize.width * 0.04;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color.fromARGB(255, 31, 35, 35),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.05),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color: AppColors.primary,
                        size: fontSize * 1.2,
                      ),
                      SizedBox(width: screenSize.width * 0.02),
                      Expanded(
                        child: Text(
                          "Pet Details",
                          style: TextStyle(
                            fontSize: fontSize * 1.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.01,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (petData['image_url'] != null &&
                              petData['image_url'].toString().isNotEmpty)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  petData['image_url'],
                                  height: screenSize.height * 0.15,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: screenSize.height * 0.15,
                                      width: double.infinity,
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: screenSize.width * 0.1,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          SizedBox(height: screenSize.height * 0.02),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Name:",
                            value: petData['name'] ?? 'Unknown',
                          ),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Species:",
                            value: petData['species'] ?? 'Unknown',
                          ),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Breed:",
                            value: petData['breed'] ?? 'Unknown',
                          ),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Age:",
                            value: "${petData['age'] ?? 'Unknown'} years",
                          ),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Gender:",
                            value: petData['gender'] ?? 'Unknown',
                          ),
                          _buildResponsiveDetailRow(
                            context: context,
                            label: "Weight:",
                            value: "${petData['weight'] ?? 'Unknown'} kg",
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Divider(
                            color: Colors.white24,
                            height: screenSize.height * 0.01,
                          ),
                          SizedBox(height: screenSize.height * 0.01),
                          Text(
                            "Pet ID:",
                            style: TextStyle(
                              fontSize: fontSize * 0.8,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            petData['id'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: fontSize * 0.8,
                              color: Colors.white70,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: fontSize * 0.9,
                          ),
                        ),
                      ),
                      SizedBox(width: screenSize.width * 0.02),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_chart, size: fontSize * 0.9),
                        label: Text(
                          "Add Records",
                          style: TextStyle(fontSize: fontSize * 0.9),
                        ),
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => VetMainhealthRecords(
                                    ownerId: petData['owner_id'],
                                    petId: petData['id'],
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.03,
                            vertical: screenSize.height * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonDialog() {
    final Size screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.04;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color.fromARGB(255, 31, 35, 35),
          title: Text(
            "Coming Soon",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: fontSize * 1.2,
            ),
          ),
          content: Text(
            "Not yet implemented",
            style: TextStyle(color: Colors.white, fontSize: fontSize),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "OK",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: fontSize * 0.9,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveDetailRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final Size screenSize = MediaQuery.of(context).size;
    final double fontSize = screenSize.width * 0.04;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.005),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenSize.width * 0.2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: fontSize, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
