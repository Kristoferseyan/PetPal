import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

  Future<List<Map<String, dynamic>>> getMedications(String petId) async {
    try {
      final List<dynamic> medicationData = await _supabase
          .from('medication_history')
          .select('id, medication_name, dosage, frequency, start_date, end_date, vet_id, notes')
          .eq('pet_id', petId)
          .order('start_date', ascending: false);

      return medicationData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch medications: ${e.toString()}");
    }
  }

  Future<List<Map<String, dynamic>>> getAllMedications() async {
    try {
      final List<dynamic> allMedications = await _supabase
          .from('medication_history')
          .select('id, medication_name, dosage, frequency, start_date, end_date, vet_id, pet_id, notes')
          .order('start_date', ascending: false);

      return allMedications.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Failed to fetch all medications: ${e.toString()}");
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getUpcomingMedicationsWithPetInfo(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final tomorrow = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      
      final List<dynamic> pets = await _supabase
          .from('pets')
          .select('id, name, pet_details!inner(image_url)')
          .eq('owner_id', userId);
      
      List<Map<String, dynamic>> todayMedications = [];
      List<Map<String, dynamic>> tomorrowMedications = [];
      
      for (var pet in pets) {
        final petId = pet['id'];
        final petName = pet['name'];
        final petImage = pet['pet_details']?[0]?['image_url']; 
        
        final petMedications = await _supabase
            .from('medication_history')
            .select('*')
            .eq('pet_id', petId)
            .lte('start_date', tomorrow)
            .gte('end_date', today);
            
        for (var med in petMedications) {
          med['pet_name'] = petName;
          med['pet_image'] = petImage;
          
          DateTime startDate = DateTime.parse(med['start_date']);
          DateTime endDate = DateTime.parse(med['end_date']);
          
          if (startDate.compareTo(DateTime(now.year, now.month, now.day)) <= 0 && 
              endDate.compareTo(DateTime(now.year, now.month, now.day)) >= 0) {
            todayMedications.add(med);
          }
          
          if (startDate.compareTo(DateTime(now.year, now.month, now.day).add(const Duration(days: 1))) <= 0 && 
              endDate.compareTo(DateTime(now.year, now.month, now.day).add(const Duration(days: 1))) >= 0) {
            tomorrowMedications.add(med);
          }
        }
      }
      
      return {
        'today': todayMedications,
        'tomorrow': tomorrowMedications,
      };
    } catch (e) {
      throw Exception("Failed to fetch upcoming medications: ${e.toString()}");
    }
  }

  Future<void> addMedication({
    required String petId,
    required String name,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      await _supabase
          .from('medication_history')
          .insert({
            'pet_id': petId,
            'medication_name': name,
            'dosage': dosage,
            'frequency': frequency,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'notes': notes,
          });
    } catch (e) {
      throw Exception("Failed to add medication: ${e.toString()}");
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _supabase
          .from('medication_history')
          .delete()
          .eq('id', medicationId);
    } catch (e) {
      throw Exception("Failed to delete medication: ${e.toString()}");
    }
  }
  
  Future<bool> isMedicationGivenToday(String medicationId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      try {
        final result = await _supabase
            .from('medication_administered')
            .select('id')
            .eq('medication_id', medicationId)
            .gte('administered_at', '$today 00:00:00')
            .lte('administered_at', '$today 23:59:59');
            
        return result.isNotEmpty;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  Future<void> markMedicationAsGiven(String medicationId) async {
    try {
      await _supabase
          .from('medication_administered')
          .insert({
            'medication_id': medicationId,
            'administered_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception("Failed to mark medication as given: $e");
    }
  }
  
  Future<int> getTodayCompletedCount(List<String> medicationIds) async {
    if (medicationIds.isEmpty) return 0;
    
    int count = 0;
    try {
      for (String id in medicationIds) {
        bool isGiven = await isMedicationGivenToday(id);
        if (isGiven) count++;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }
}
