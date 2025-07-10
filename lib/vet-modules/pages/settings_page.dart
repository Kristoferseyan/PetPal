import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(),
              ListTile(
                title: Text(
                  'Change Password',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(Icons.lock, color: Colors.white),
                onTap: () {},
              ),
              ListTile(
                title: Text(
                  'Privacy Settings',
                  style: TextStyle(color: Colors.white),
                ),
                leading: Icon(Icons.privacy_tip, color: Colors.white),
                onTap: () {},
              ),
              Divider(),
              Spacer(),

              Center(
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cancel,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
