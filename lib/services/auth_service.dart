import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });
}

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw "User registration failed.";
      }

      final userId = response.user!.id;
      await supabase.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role': 'pet_owner',
        'created_at': DateTime.now().toIso8601String(),
      });

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVets() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, full_name, email')
          .eq('role', 'vet');

      final List<Map<String, dynamic>> vets = List<Map<String, dynamic>>.from(
        response,
      );

      return vets;
    } catch (e) {
      return [];
    }
  }

  Future<String?> getDefaultVetId() async {
    try {
      final vets = await getVets();
      if (vets.isNotEmpty) {
        return vets[0]['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final userData =
          await supabase
              .from('users')
              .select('full_name, email, id, role')
              .eq('id', user.id)
              .single();

      final profileData =
          await supabase
              .from('user_profiles')
              .select('profile_image, phone, address')
              .eq('user_id', user.id)
              .maybeSingle();

      if (profileData != null) {
        userData['profile_image'] = profileData['profile_image'];
        userData['phone'] = profileData['phone'];
        userData['address'] = profileData['address'];
      }

      return userData;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOwnerByName(String name) async {
    try {
      final response =
          await supabase
              .from('users')
              .select('id, full_name')
              .eq('full_name', name)
              .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPetOwners() async {
    try {
      final response = await supabase
          .from('users')
          .select('id, full_name, email')
          .eq('role', 'pet_owner');

      final List<Map<String, dynamic>> owners = List<Map<String, dynamic>>.from(
        response,
      );

      for (var owner in owners) {
        try {
          final List<dynamic> profileResponses = await supabase
              .from('user_profiles')
              .select('phone, address')
              .eq('user_id', owner['id']);

          if (profileResponses.isNotEmpty) {
            final profileData = profileResponses[0];

            owner['phone'] = profileData['phone']?.toString() ?? 'Not provided';
            owner['address'] =
                profileData['address']?.toString() ?? 'Not provided';
          } else {
            owner['phone'] = 'Not provided';
            owner['address'] = 'Not provided';
          }
        } catch (e) {
          owner['phone'] = 'Not provided';
          owner['address'] = 'Not provided';
        }
      }

      return owners;
    } catch (e) {
      return [];
    }
  }

  Future<void> recordUserLogin(String userId) async {
    try {
      await supabase.from('user_logins').insert({'user_id': userId});
    } catch (e) {
      // Error recording login
    }
  }

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await recordUserLogin(response.user!.id);

        return response;
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateUserName(String newName) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await supabase
          .from('users')
          .update({'full_name': newName})
          .eq('id', user.id);

      await supabase.auth.updateUser(
        UserAttributes(data: {'full_name': newName}),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final userData =
          await supabase
              .from('users')
              .select('id, full_name, role')
              .eq('id', user.id)
              .single();

      return User(
        id: user.id,
        email: user.email ?? "",
        fullName: userData['full_name'] ?? "",
        role: userData['role'] ?? "pet_owner",
      );
    } catch (e) {
      return null;
    }
  }

  String? getCurrentUserDisplayName() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['name'] ?? user?.email;
  }
}
