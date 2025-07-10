import 'package:flutter/material.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_appointment_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_home_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_pet_management_page.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_settings_page.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/utils/petOwner_gnav.dart';
import 'package:petpal/vet-modules/pages/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetOwnerDashboard extends StatefulWidget {
  final int initialIndex;
  const PetOwnerDashboard({super.key, required this.initialIndex});

  @override
  State<PetOwnerDashboard> createState() => _PetOwnerDashboardState();
}

class _PetOwnerDashboardState extends State<PetOwnerDashboard> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;
  String? _ownerId;

  final GlobalKey<PetOwnerHomePageState> _homePageKey =
      GlobalKey<PetOwnerHomePageState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _ownerId = user.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth > 700;
    double navbarHeight = 80;

    List<Widget> widgetOptions = <Widget>[
      PetOwnerHomePage(key: _homePageKey),

      const PetOwnerAppointmentsPage(),

      const PetManagementPage(),

      const SettingsPage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_selectedIndex == 0) {
          final bool shouldExit = await _showExitConfirmationDialog();
          if (shouldExit) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body:
            isDesktop
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
                : Center(child: widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: PetOwnerGnav(
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });

            if (index == 0 && _selectedIndex != 0) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (_homePageKey.currentState != null) {
                  _homePageKey.currentState!.refreshData();
                }
              });
            }
          },
          selectedIndex: _selectedIndex,
          navbarHeight: navbarHeight,
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return (await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit the app?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
        )) ??
        false;
  }
}
