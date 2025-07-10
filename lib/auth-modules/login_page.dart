import 'package:flutter/material.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      final lastEmail = prefs.getString('last_email') ?? '';
      setState(() {
        _rememberMe = rememberMe;
        _emailController.text = lastEmail;
        
        if (lastEmail.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        }
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService().login(_emailController.text.trim(), _passwordController.text.trim());

      if (response != null && response.session != null) {
        final userId = response.user!.id;

        
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          await prefs.setString('last_email', _emailController.text.trim());
          
          
          
        } else {
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', false);
          await prefs.remove('last_email');
        }

        
        final data = await supabase.from('users').select('role').eq('id', userId).single();

        if (data != null && data['role'] != null) {
          String role = data['role'];

          if (role == 'admin') {
          } else if (role == 'pet_owner') {
            Navigator.pushReplacementNamed(context, '/pet-owner-dashboard');
          } else if (role == 'vet_clinic') {
            Navigator.pushReplacementNamed(context, '/vet');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _errorMessage = "User role not found.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Invalid credentials. Please try again.";
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          bool isWideScreen = screenWidth > 600;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: isWideScreen ? 100.0 : 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/petpal.png',
                      height: isWideScreen ? 180 : 140,
                    ),
                    SizedBox(height: isWideScreen ? 30 : 20),
                    Text(
                      "Login to PetPal",
                      style: TextStyle(
                        fontSize: isWideScreen ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: AppColors.primary),
                        prefixIcon: Icon(Icons.email, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: AppColors.primary),
                        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.accent,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColors.primary;
                            }
                            return Colors.white38;
                          }),
                          side: BorderSide(color: Colors.white60),
                        ),
                        Text(
                          "Remember Me",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                              EdgeInsets.symmetric(vertical: isWideScreen ? 18 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: AppColors.background)
                            : Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 18, color: AppColors.background),
                              ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            "Register",
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
