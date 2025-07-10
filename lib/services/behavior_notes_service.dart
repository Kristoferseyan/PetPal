import 'package:supabase_flutter/supabase_flutter.dart';

class BehaviorNoteService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<Map<String, dynamic>> addBehaviorNote({
    required String petId,
    required String note,
    required String mood,
  }) async {
    final response = await _supabase
      .from('pet_behavior_notes')
      .insert({
        'pet_id': petId,
        'note': note,
        'mood': mood,
      })
      .select()
      .single();
      
    return response;
  }
  
  Future<List<Map<String, dynamic>>> getBehaviorNotes(String petId) async {
    final response = await _supabase
      .from('pet_behavior_notes')
      .select()
      .eq('pet_id', petId)
      .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<void> updateBehaviorNote({
    required String noteId,
    String? note,
    String? mood,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (note != null) updates['note'] = note;
    if (mood != null) updates['mood'] = mood;
    
    await _supabase
      .from('pet_behavior_notes')
      .update(updates)
      .eq('id', noteId);
  }
  
  Future<void> deleteBehaviorNote(String noteId) async {
    await _supabase
      .from('pet_behavior_notes')
      .delete()
      .eq('id', noteId);
  }
}