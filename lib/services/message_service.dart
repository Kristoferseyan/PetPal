import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('conversations')
          .select('*')
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': _supabase.auth.currentUser!.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createConversation({
    required String participantId,
    String? name,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .or('and(participant1_id.eq.$userId,participant2_id.eq.$participantId),and(participant1_id.eq.$participantId,participant2_id.eq.$userId)')
          .maybeSingle();
      if (existing != null) {
        return existing['id'] as String;
      }
      final response = await _supabase
          .from('conversations')
          .insert({
            'participant1_id': userId,
            'participant2_id': participantId,
            'name': name,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response['id'] as String;
    } catch (e) {
      return null;
    }
  }

  RealtimeChannel subscribeToMessages(Function onReceive) {
    final channel = _supabase
      .channel('public:messages')
      .onPostgresChanges( 
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          onReceive(payload);
        }
      );
    channel.subscribe();
    return channel;
  }

  Future<Map<String, dynamic>?> getParticipantInfo(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final conversation = await _supabase
          .from('conversations')
          .select('participant1_id, participant2_id')
          .eq('id', conversationId)
          .single();
      final otherParticipantId = conversation['participant1_id'] == userId
          ? conversation['participant2_id']
          : conversation['participant1_id'];
      final user = await _supabase
          .from('users')
          .select('id, full_name, email, role')
          .eq('id', otherParticipantId)
          .single();
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<String> getLastMessage(String conversationId) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select('content')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);
      if (messages.isNotEmpty) {
        return messages[0]['content'];
      }
      return 'No messages yet';
    } catch (e) {
      return 'No messages yet';
    }
  }

  Future<Map<String, dynamic>?> getMessage(String messageId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}
