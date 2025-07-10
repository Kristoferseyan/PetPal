import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalService {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

  Future<void> addMedicalRecord({
    required String petId,
    required String diagnosis,
    required String treatment,
    required DateTime date,
    String? vetId,
    String? notes,
  }) async {
    try {
      final record =
          await _supabase
              .from('medical_history')
              .insert({
                'pet_id': petId,
                'diagnosis': diagnosis,
                'treatment': treatment,
                'date': date.toIso8601String(),
                'vet_id': vetId,
                'notes': notes,
              })
              .select()
              .single();

    } catch (e) {
      throw Exception("Failed to add medical record: ${e.toString()}");
    }
  }

  Future<void> archiveRecord(String recordId) async {
    try {

      final result =
          await _supabase
              .from('medical_history')
              .update({'archived': true})
              .eq('id', recordId)
              .select()
              .single();

    } catch (e) {
      throw Exception("Failed to archive record: ${e.toString()}");
    }
  }

  Future<List<Map<String, dynamic>>> getCompleteMedicalHistory(
    String petId,
  ) async {
    try {
      final vetRecords = await _supabase
          .from('medical_history')
          .select('*')
          .eq('pet_id', petId)
          .eq('archived', false)
          .order('created_at', ascending: false);

      final vetRecordsWithSource =
          vetRecords.map<Map<String, dynamic>>((record) {
            return {...record, 'source': 'vet'};
          }).toList();

      final petDetailsResponse =
          await _supabase
              .from('pet_details')
              .select('medical_record_url')
              .eq('pet_id', petId)
              .single();

      List<Map<String, dynamic>> ownerRecords = [];

      if (petDetailsResponse != null &&
          petDetailsResponse['medical_record_url'] != null &&
          petDetailsResponse['medical_record_url'].toString().isNotEmpty) {
        ownerRecords.add({
          'id': 'owner-${petId}',
          'pet_id': petId,
          'diagnosis': 'Owner-Provided Medical Document',
          'treatment': 'See attached document',
          'notes': 'This record was uploaded by the pet owner',
          'image_url': petDetailsResponse['medical_record_url'],
          'created_at': DateTime.now().toIso8601String(),
          'source': 'owner',
        });
      }

      return [...vetRecordsWithSource, ...ownerRecords];
    } catch (e) {
      throw Exception("Failed to fetch medical records: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getPetsByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('pets')
          .select('id, name, photo_url, pet_details(species, breed)')
          .eq('owner_id', ownerId)
          .eq('is_deleted', false);

      final transformedPets =
          response.map<Map<String, dynamic>>((pet) {
            final petDetails = pet['pet_details'] as Map<String, dynamic>?;

            return {
              'id': pet['id'],
              'name': pet['name'] ?? 'Unnamed Pet',
              'photo_url': pet['photo_url'],
              'species': petDetails?['species'] ?? 'Unknown',
              'breed': petDetails?['breed'],
            };
          }).toList();

      return transformedPets;
    } catch (e) {
      throw Exception("Failed to fetch pets: ${e.toString()}");
    }
  }

  Future<void> unarchiveRecord(String recordId) async {
    try {

      final result =
          await _supabase
              .from('medical_history')
              .update({'archived': false})
              .eq('id', recordId)
              .select()
              .single();

    } catch (e) {
      throw Exception("Failed to unarchive record: ${e.toString()}");
    }
  }

  // Modify getMedicalHistory to filter out archived records by default
  Future<List<Map<String, dynamic>>> getMedicalHistory(
    String petId, {
    bool includeArchived = false,
  }) async {
    try {
      var query = _supabase
          .from('medical_history')
          .select('*')
          .eq('pet_id', petId);

      // Only show non-archived records unless requested
      if (!includeArchived) {
        query = query.eq('archived', false);
      }

      final List<dynamic> historyData = await query.order(
        'date',
        ascending: false,
      );

      return historyData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch medical history: ${e.toString()}");
    }
  }

  // Add a method to get only archived records
  Future<List<Map<String, dynamic>>> getArchivedMedicalHistory(
    String petId,
  ) async {
    try {
      final List<dynamic> historyData = await _supabase
          .from('medical_history')
          .select('*')
          .eq('pet_id', petId)
          .eq('archived', true)
          .order('date', ascending: false);

      return historyData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception(
        "Failed to fetch archived medical history: ${e.toString()}",
      );
    }
  }

  Future<Map<String, dynamic>> updateMedicalRecord({
    required String recordId,
    String? diagnosis,
    String? treatment,
    String? notes,
    String? imageUrl,
    bool? removeImage = false, // Add this flag
  }) async {
    try {

      Map<String, dynamic> updates = {};

      if (diagnosis != null) updates['diagnosis'] = diagnosis;
      if (treatment != null) updates['treatment'] = treatment;
      if (notes != null) updates['notes'] = notes;

      // Handle image_url explicitly
      if (removeImage == true || imageUrl == null) {
        // Explicitly set to null to remove the image
        updates['image_url'] = null;
      } else
        updates['image_url'] = imageUrl;


      final result =
          await _supabase
              .from('medical_history')
              .update(updates)
              .eq('id', recordId)
              .select()
              .single();

      return result;
    } catch (e) {
      throw Exception("Failed to update medical record: ${e.toString()}");
    }
  }

  Future<void> deleteMedicalRecord(String recordId) async {
    try {
      await _supabase.from('medical_history').delete().eq('id', recordId);
    } catch (e) {
      throw Exception("Failed to delete medical record: ${e.toString()}");
    }
  }

  // Payment tracking methods
  Future<void> createPaymentRecord({
    required String appointmentId,
    required String petOwnerId,
    required double amount,
    required String paymentMethod,
    required String description,
    String? paymentIntentId,
    String? transactionId,
  }) async {
    try {
      await _supabase.from('appointment_payments').insert({
        'appointment_id': appointmentId,
        'pet_owner_id': petOwnerId,
        'amount': amount,
        'currency': 'PHP',
        'payment_method': paymentMethod,
        'status': 'pending',
        'description': description,
        'payment_intent_id': paymentIntentId,
        'transaction_id': transactionId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Failed to create payment record: ${e.toString()}");
    }
  }

  Future<void> updatePaymentStatus({
    required String appointmentId,
    required String status,
    String? transactionId,
    DateTime? paidAt,
  }) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updates['transaction_id'] = transactionId;
      }

      if (paidAt != null) {
        updates['paid_at'] = paidAt.toIso8601String();
      }

      await _supabase
          .from('appointment_payments')
          .update(updates)
          .eq('appointment_id', appointmentId);
    } catch (e) {
      throw Exception("Failed to update payment status: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>?> getPaymentForAppointment(
    String appointmentId,
  ) async {
    try {
      final response =
          await _supabase
              .from('appointment_payments')
              .select('*')
              .eq('appointment_id', appointmentId)
              .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentsForOwner(
    String petOwnerId,
  ) async {
    try {
      final response = await _supabase
          .from('appointment_payments')
          .select('*, appointments(appointment_date, pets(name))')
          .eq('pet_owner_id', petOwnerId)
          .order('created_at', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}
