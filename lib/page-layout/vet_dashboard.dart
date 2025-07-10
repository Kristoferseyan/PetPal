import 'package:flutter/material.dart';
import 'package:petpal/utils/vet_gnav.dart';
import 'package:petpal/vet-modules/pages/vet_health_record_page.dart';
import 'package:petpal/vet-modules/pages/settings_page.dart';
import 'package:petpal/vet-modules/pages/vet_home_page.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/vet-modules/pages/vet_mainHealth_records.dart';
import 'package:petpal/vet-modules/pages/vet_medication_page.dart';
import 'package:petpal/vet-modules/pages/vet_message_page.dart';


class VetDashboard extends StatefulWidget {
  final int initialIndex;
  const VetDashboard({
    super.key,
    required this.initialIndex,
  });

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 700;
    double navbarHeight = 80;

    
    List<Widget> widgetOptions = <Widget>[
      StaffPage(),  
      MedicationManagementPage(),
      SettingsPage()  
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: widgetOptions.elementAt(_selectedIndex),
                  ),
                ),
              ],
            )
          : Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
      bottomNavigationBar: VetGnav(
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        navbarHeight: navbarHeight,
      ),
    );
  }
}
