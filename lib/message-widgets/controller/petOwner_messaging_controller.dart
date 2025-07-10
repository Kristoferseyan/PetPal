import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/services/message_service.dart';

class PetOwnerMessagingController extends ChangeNotifier {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController messageTextController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _conversations = [];
  String? _selectedConversationId;
  String? _selectedParticipantName;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  RealtimeChannel? _messageSubscription;
  RealtimeChannel? _conversationSubscription;
  
  
  List<Map<String, dynamic>> get conversations => _conversations;
  String? get selectedConversationId => _selectedConversationId;
  String? get selectedParticipantName => _selectedParticipantName;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String get currentUserId => _supabase.auth.currentUser!.id;
  
  void init() {
    loadConversations();
    _setupRealtimeSubscriptions();
  }
  
  @override
  void dispose() {
    messageTextController.dispose();
    _messageSubscription?.unsubscribe();
    _conversationSubscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    
    _messageSubscription = _supabase
        .channel('pet_owner:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            
            final conversationId = payload.newRecord['conversation_id'] as String;
            
            if (conversationId == _selectedConversationId) {
              try {
                final messageId = payload.newRecord['id'];
                final newMessage = await _messagingService.getMessage(messageId);
                if (newMessage != null) {
                  _messages = [..._messages, newMessage];
                  notifyListeners();
                }
              } catch (e) {
                await loadMessages(conversationId);
              }
            }
            
            await loadConversations();
          },
        )
        .subscribe();
        
    _conversationSubscription = _supabase
        .channel('pet_owner:conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            loadConversations();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            loadConversations();
          },
        )
        .subscribe();
  }
  
  void clearSelectedConversation() {
    _selectedConversationId = null;
    _selectedParticipantName = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      
      final conversations = await _messagingService.getConversations();
      
      
      for (var i = 0; i < conversations.length; i++) {
        conversations[i]['lastMessage'] = 
            await _messagingService.getLastMessage(conversations[i]['id']);
        
        
        final participant = await _messagingService.getParticipantInfo(conversations[i]['id']);
        if (participant != null) {
          conversations[i]['participantName'] = participant['full_name'];
          conversations[i]['participantEmail'] = participant['email'];
          conversations[i]['participantRole'] = participant['role'];
        }
      }
      
      _conversations = conversations;
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void selectConversation(String conversationId, String participantName) {
    _selectedConversationId = conversationId;
    _selectedParticipantName = participantName;
    loadMessages(conversationId);
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    _isLoadingMessages = true;
    notifyListeners();
    
    try {
      final messages = await _messagingService.getMessages(conversationId);
      _messages = messages;
    } catch (e) {
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage() async {
    if (messageTextController.text.trim().isEmpty || _selectedConversationId == null) {
      return false;
    }
    
    final message = messageTextController.text.trim();
    messageTextController.clear();
    
    try {
      
      final optimisticMessage = {
        'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': _selectedConversationId,
        'sender_id': currentUserId,
        'content': message,
        'created_at': DateTime.now().toIso8601String(),
        'is_pending': true,
      };
      
      _messages = [..._messages, optimisticMessage];
      notifyListeners();
      
      
      final success = await _messagingService.sendMessage(
        conversationId: _selectedConversationId!,
        content: message,
      );
      
      if (!success) {
        
        _messages = _messages.where((m) => m['id'] != optimisticMessage['id']).toList();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }
}