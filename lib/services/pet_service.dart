import 'package:supabase_flutter/supabase_flutter.dart';

class PetService {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

  int _calculateAgeFromBirthdate(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) return 0;

    try {
      final birthdate = DateTime.parse(birthdateStr);
      final now = DateTime.now();
      int age = now.year - birthdate.year;

      if (now.month < birthdate.month ||
          (now.month == birthdate.month && now.day < birthdate.day)) {
        age--;
      }

      return age < 0 ? 0 : age;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPets() async {
    try {
      final List<dynamic> petsData = await _supabase
          .from('pets')
          .select('id, name')
          .eq('is_deleted', false);

      if (petsData.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> petsWithDetails = [];

      for (var pet in petsData) {
        final petId = pet['id'];

        final petDetails =
            await _supabase
                .from('pet_details')
                .select('species, breed, birthdate, gender, image_url, weight')
                .eq('pet_id', petId)
                .single();

        String imageUrl = petDetails['image_url'] ?? '';
        String fallbackImage = 'assets/images/placeholder.jpg';

        if (imageUrl.isNotEmpty) {
          if (imageUrl.contains('/')) {
            imageUrl = 'file://$imageUrl';
          } else if (imageUrl.startsWith('data:image')) {
            imageUrl = 'data:image/png;base64,' + imageUrl.split(',').last;
          }
        } else {
          imageUrl = fallbackImage;
        }

        // Calculate age from birthdate
        final birthdate = petDetails['birthdate'];
        final age = _calculateAgeFromBirthdate(birthdate);

        petsWithDetails.add({
          'id': pet['id'],
          'name': pet['name'],
          'species': petDetails['species'] ?? 'Unknown',
          'breed': petDetails['breed'] ?? 'Unknown',
          'birthdate': birthdate,
          'age': age,
          'gender': petDetails['gender'] ?? 'Unknown',
          'imageUrl': imageUrl,
          'weight':
              petDetails['weight'] != null
                  ? double.tryParse(petDetails['weight'].toString()) ?? 0.0
                  : 0.0,
        });
      }

      return petsWithDetails;
    } catch (e) {
      throw Exception("Failed to fetch pets: ${e.toString()}");
    }
  }

  Future<List<String>> getPetIdsByOwnerId(String ownerId) async {
    try {
      final petData = await _supabase
          .from('pets')
          .select('id')
          .eq('is_deleted', false)
          .eq('owner_id', ownerId);

      if (petData.isEmpty) {
        return [];
      }

      return petData.map<String>((pet) => pet['id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentPetsWithAppointments(
    String vetId,
  ) async {
    try {
      final result = await _supabase
          .from('appointments')
          .select('pet_id, pets(name, id), appointment_date')
          .eq('vet_id', vetId)
          .order('appointment_date', ascending: false)
          .limit(5);

      if (result.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> petsWithDetails = [];

      for (var data in result) {
        final petId = data['pet_id'];

        final petDetails =
            await _supabase
                .from('pet_details')
                .select('species, breed, birthdate, gender, weight, image_url')
                .eq('pet_id', petId)
                .single();

        final birthdate = petDetails['birthdate'];
        final age = _calculateAgeFromBirthdate(birthdate);

        petsWithDetails.add({
          'petId': data['pet_id'],
          'petName': data['pets']['name'],
          'species': petDetails['species'] ?? 'Unknown',
          'breed': petDetails['breed'] ?? 'Unknown',
          'birthdate': birthdate,
          'age': age,
          'gender': petDetails['gender'] ?? 'Unknown',
          'weight': petDetails['weight'] ?? 0.0,
          'imageUrl':
              petDetails['image_url'] ?? 'assets/images/placeholder.jpg',
          'appointmentDate': data['appointment_date'],
        });
      }

      return petsWithDetails;
    } catch (e) {
      throw Exception(
        "Failed to fetch recent pets with appointments: ${e.toString()}",
      );
    }
  }

  Future<List<String>> getPetNamesByOwnerId(String ownerId) async {
    try {
      final petData = await _supabase
          .from('pets')
          .select('name')
          .eq('owner_id', ownerId);

      if (petData.isEmpty) {
        return [];
      }

      return petData.map<String>((pet) => pet['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> getPetIdByOwnerId(String ownerId) async {
    try {
      final petData =
          await _supabase
              .from('pets')
              .select('id')
              .eq('owner_id', ownerId)
              .eq('is_deleted', false)
              .single();

      return petData['id'];
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPetsByOwner(String ownerId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('pets')
          .select('''
            *,
            pet_details(*)
          ''')
          .eq('owner_id', ownerId)
          .eq('is_deleted', false)
          .order('name');

      List<Map<String, dynamic>> normalizedPets =
          data.map((pet) {
            Map<String, dynamic> petDetails = {};

            if (pet['pet_details'] != null) {
              if (pet['pet_details'] is Map) {
                petDetails = pet['pet_details'];
              } else if (pet['pet_details'] is List &&
                  pet['pet_details'].isNotEmpty) {
                petDetails = pet['pet_details'][0];
              }
            }

            final birthdate = petDetails['birthdate'];
            final age = _calculateAgeFromBirthdate(birthdate);

            return {
              'id': pet['id'],
              'name': pet['name'],
              'owner_id': pet['owner_id'],
              'species': petDetails['species'] ?? 'Unknown',
              'breed': petDetails['breed'] ?? 'Unknown',
              'birthdate': birthdate,
              'age': age,
              'gender': petDetails['gender'] ?? 'Unknown',
              'image_url': petDetails['image_url'] ?? '',
              'weight': petDetails['weight'],
              'is_deleted': pet['is_deleted'] ?? false,
              'pet_details': pet['pet_details'],
            };
          }).toList();

      return normalizedPets;
    } catch (e) {
      throw Exception('Failed to load pets');
    }
  }

  Future<List<Map<String, dynamic>>> getPets(String ownerId) async {
    try {
      final List<dynamic> petsData = await _supabase
          .from('pets')
          .select('id, name')
          .eq('owner_id', ownerId)
          .eq('is_deleted', false);

      if (petsData.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> petsWithDetails = [];

      for (var pet in petsData) {
        final petId = pet['id'];

        final petDetails =
            await _supabase
                .from('pet_details')
                .select('species, breed, birthdate, gender, image_url, weight')
                .eq('pet_id', petId)
                .single();

        String imageUrl =
            petDetails['image_url'] ?? 'https://example.com/default-image.png';

        if (imageUrl.isEmpty) {
          imageUrl = 'assets/images/placeholder.jpg';
        }

        final birthdate = petDetails['birthdate'];
        final age = _calculateAgeFromBirthdate(birthdate);

        petsWithDetails.add({
          'id': pet['id'],
          'name': pet['name'],
          'species': petDetails['species'] ?? 'Unknown',
          'breed': petDetails['breed'] ?? 'Unknown',
          'birthdate': birthdate,
          'age': age,
          'gender': petDetails['gender'] ?? 'Unknown',
          'imageUrl': imageUrl,
          'weight':
              petDetails['weight'] != null
                  ? double.tryParse(petDetails['weight'].toString()) ?? 0.0
                  : 0.0,
        });
      }

      return petsWithDetails;
    } catch (e) {
      throw Exception("Failed to fetch pets: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> getPet(String petId) async {
    try {
      final data =
          await _supabase
              .from('pets')
              .select('''
            id, 
            name, 
            owner_id,
            pet_details:pet_details(
              species, 
              breed, 
              birthdate, 
              gender, 
              image_url, 
              weight
            )
          ''')
              .eq('id', petId)
              .eq('is_deleted', false)
              .single();

      final petDetails = data['pet_details'] ?? {};

      final birthdate = petDetails['birthdate'];
      final age = _calculateAgeFromBirthdate(birthdate);

      return {
        'id': data['id'],
        'name': data['name'],
        'ownerId': data['owner_id'],
        'species': petDetails['species'] ?? 'Unknown',
        'breed': petDetails['breed'] ?? 'Unknown',
        'birthdate': birthdate,
        'age': age,
        'gender': petDetails['gender'] ?? 'Unknown',
        'imageUrl': petDetails['image_url'] ?? 'assets/images/placeholder.jpg',
        'weight':
            petDetails['weight'] != null
                ? double.tryParse(petDetails['weight'].toString()) ?? 0.0
                : 0.0,
        'isNeutered': petDetails['is_neutered'] ?? false,
        'allergies': petDetails['allergies'] ?? '',
        'markings': petDetails['markings'] ?? '',
        'medicalRecordUrl': petDetails['medical_record_url'] ?? '',
      };
    } catch (e) {
      throw Exception("Failed to fetch pet: ${e.toString()}");
    }
  }

  Future<void> addPet({
    required String ownerId,
    required String name,
    required String species,
    required String breed,
    required DateTime birthdate,
    required String gender,
    String imageUrl = '',
    double weight = 0.0,
    bool isNeutered = false,
    String allergies = '',
    String markings = '',
    String medicalRecordUrl = '',
  }) async {
    final petResponse =
        await _supabase
            .from('pets')
            .insert({'owner_id': ownerId, 'name': name, 'is_active': true})
            .select()
            .single();

    final petId = petResponse['id'];

    await _supabase.from('pet_details').insert({
      'pet_id': petId,
      'species': species,
      'breed': breed,
      'birthdate': birthdate.toIso8601String(),
      'gender': gender,
      'image_url': imageUrl,
      'weight': weight,
      'is_neutered': isNeutered,
      'allergies': allergies,
      'markings': markings,
      'medical_record_url': medicalRecordUrl,
    });
  }

  Future<bool> softDeletePet(String petId) async {
    try {
      final response = await supabase
          .from('pets')
          .update({'is_deleted': true})
          .eq('id', petId);

      if (response != null && response.error != null) {
        throw Exception('Failed to delete pet: ${response.error!.message}');
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  Future<void> updatePet({
    required String petId,
    required String name,
    required String species,
    required String breed,
    required DateTime birthdate,
    required String gender,
    String imageUrl = '',
    double weight = 0.0,
    bool isNeutered = false,
    String allergies = '',
    String markings = '',
    String medicalRecordUrl = '',
  }) async {
    await _supabase.from('pets').update({'name': name}).eq('id', petId);

    await _supabase
        .from('pet_details')
        .update({
          'species': species,
          'breed': breed,
          'birthdate': birthdate.toIso8601String(),
          'gender': gender,
          'image_url': imageUrl,
          'weight': weight,
          'is_neutered': isNeutered,
          'allergies': allergies,
          'markings': markings,
          'medical_record_url': medicalRecordUrl,
        })
        .eq('pet_id', petId);
  }

  Future<void> deletePet(String petId) async {
    try {
      await _supabase.from('pets').delete().eq('id', petId);
    } catch (e) {
      throw Exception("Failed to delete pet: ${e.toString()}");
    }
  }

  Future<List<Map<String, dynamic>>> getPetsDetailsByOwnerId(
    String ownerId,
  ) async {
    try {
      final response = await _supabase
          .from('pets')
          .select('id, name, pet_details(species, breed, birthdate)')
          .eq('owner_id', ownerId)
          .eq('is_deleted', false);

      final pets = List<Map<String, dynamic>>.from(response);

      for (var pet in pets) {
        final petDetails = pet['pet_details'];
        if (petDetails != null) {
          if (petDetails is List && petDetails.isNotEmpty) {
            pet['species'] = petDetails[0]['species'];
            pet['breed'] = petDetails[0]['breed'];
            pet['birthdate'] = petDetails[0]['birthdate'];

            final birthdate = pet['birthdate'];
            pet['age'] = _calculateAgeFromBirthdate(birthdate);
          } else if (petDetails is Map) {
            pet['species'] = petDetails['species'];
            pet['breed'] = petDetails['breed'];
            pet['birthdate'] = petDetails['birthdate'];

            final birthdate = pet['birthdate'];
            pet['age'] = _calculateAgeFromBirthdate(birthdate);
          }
        }
      }

      return pets;
    } catch (e) {
      return [];
    }
  }

  Future<void> trackPetAccess(String petId) async {
    try {
      bool hasRecentPetsTable = false;
      try {
        await _supabase.from('recent_pets').select('id').limit(1);
        hasRecentPetsTable = true;
      } catch (e) {
        return;
      }

      if (hasRecentPetsTable) {
        final existingRecord =
            await _supabase
                .from('recent_pets')
                .select('id')
                .eq('pet_id', petId)
                .maybeSingle();

        if (existingRecord != null) {
          await _supabase
              .from('recent_pets')
              .update({'accessed_at': DateTime.now().toIso8601String()})
              .eq('id', existingRecord['id']);
        } else {
          await _supabase.from('recent_pets').insert({
            'pet_id': petId,
            'accessed_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {}
  }

  Future<bool> petHasOngoingAppointments(String petId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final appointments = await _supabase
          .from('appointments')
          .select('id')
          .eq('pet_id', petId)
          .or('status.eq.pending,status.eq.approved,status.eq.on-going')
          .gte('appointment_date', now)
          .limit(1);

      return appointments.isNotEmpty;
    } catch (e) {
      return true;
    }
  }
}
