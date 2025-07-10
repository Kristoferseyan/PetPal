import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();

    _checkRememberedLogin();
  }

  Future<void> _checkRememberedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe) {
        final session = supabase.auth.currentSession;
        if (session != null && session.isExpired == false) {
          final userId = session.user.id;

          try {
            final data =
                await supabase
                    .from('users')
                    .select('role')
                    .eq('id', userId)
                    .single();

            if (data != null && data['role'] != null) {
              String role = data['role'];

              if (!mounted) return;

              Future.delayed(Duration.zero, () {
                if (role == 'admin') {
                } else if (role == 'pet_owner') {
                  Navigator.pushReplacementNamed(
                    context,
                    '/pet-owner-dashboard',
                  );
                } else if (role == 'vet_clinic') {
                  Navigator.pushReplacementNamed(context, '/vet');
                }
              });

              return;
            }
          } catch (e) {
          }
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _checkingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body:
          _checkingSession
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = constraints.maxWidth;

                  bool isWideScreen = screenWidth > 600;

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 100.0 : 20.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/petpal.png',

                            height: isWideScreen ? 200 : 150,
                          ),

                          SizedBox(height: isWideScreen ? 30 : 20),

                          Text(
                            "Welcome to PetPal!",
                            style: TextStyle(
                              fontSize: isWideScreen ? 32 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 10),

                          Text(
                            "Easily track your pet's health and records in one place.",
                            style: TextStyle(
                              fontSize: isWideScreen ? 18 : 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: isWideScreen ? 50 : 30),

                          SizedBox(
                            width: isWideScreen ? 300 : double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWideScreen ? 50 : 40,
                                  vertical: isWideScreen ? 20 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: isWideScreen ? 20 : 16,
                                  color: AppColors.background,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10),

                          SizedBox(
                            width: isWideScreen ? 300 : double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWideScreen ? 50 : 40,
                                  vertical: isWideScreen ? 20 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: AppColors.secondary),
                              ),
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: isWideScreen ? 20 : 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
