import 'package:flutter/material.dart';
import 'package:petpal/message-widgets/controller/vet_messaging_controller.dart';
import 'package:petpal/message-widgets/vet_conversation_list.dart';
import 'package:petpal/message-widgets/empty_states.dart';
import 'package:petpal/message-widgets/message_input.dart';
import 'package:petpal/message-widgets/message_list.dart';
import 'package:petpal/message-widgets/utils/message_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petpal/services/message_service.dart';
import 'package:petpal/utils/colors.dart';

class VetMessagePage extends StatefulWidget {
  const VetMessagePage({Key? key}) : super(key: key);

  @override
  State<VetMessagePage> createState() => _VetMessagePageState();
}

class _VetMessagePageState extends State<VetMessagePage> {
  final VetMessagingController _controller = VetMessagingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: () async {
        if (_controller.selectedConversationId != null && isMobile) {
          setState(() {
            _controller.clearSelectedConversation();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 37, 45, 50),
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          automaticallyImplyLeading:
              _controller.selectedConversationId != null && isMobile,
          title: Row(
            children: [
              Icon(Icons.pets, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _controller.selectedConversationId != null && isMobile
                    ? _controller.selectedParticipantName ?? 'Chat'
                    : 'Messages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 44, 59, 70),
          elevation: 0,
          leading:
              _controller.selectedConversationId != null && isMobile
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _controller.clearSelectedConversation();
                      });
                    },
                  )
                  : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed:
                  _controller.selectedConversationId != null && isMobile
                      ? () => _controller.loadMessages(
                        _controller.selectedConversationId!,
                      )
                      : _controller.loadConversations,
            ),
          ],
        ),
        body:
            _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : isMobile
                ? _controller.selectedConversationId == null
                    ? VetConversationListWidget(
                      conversations: _controller.conversations,
                      onSelect: _controller.selectConversation,
                      onNewConversation: _showNewConversationDialog,
                    )
                    : Column(
                      children: [
                        Expanded(
                          child:
                              _controller.isLoadingMessages
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _controller.messages.isEmpty
                                  ? const EmptyMessagesView()
                                  : MessageListWidget(
                                    messages: _controller.messages,
                                    currentUserId: _controller.currentUserId,
                                  ),
                        ),
                        MessageInputWidget(
                          controller: _controller.messageTextController,
                          onSend: _controller.sendMessage,
                        ),
                      ],
                    )
                : Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: VetConversationListWidget(
                        conversations: _controller.conversations,
                        selectedId: _controller.selectedConversationId,
                        onSelect: _controller.selectConversation,
                        onNewConversation: _showNewConversationDialog,
                      ),
                    ),

                    Container(width: 1, color: Colors.grey[800]),

                    Expanded(
                      child:
                          _controller.selectedConversationId == null
                              ? const NoConversationSelectedView()
                              : Column(
                                children: [
                                  Expanded(
                                    child:
                                        _controller.isLoadingMessages
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : _controller.messages.isEmpty
                                            ? const EmptyMessagesView()
                                            : MessageListWidget(
                                              messages: _controller.messages,
                                              currentUserId:
                                                  _controller.currentUserId,
                                            ),
                                  ),
                                  MessageInputWidget(
                                    controller:
                                        _controller.messageTextController,
                                    onSend: _controller.sendMessage,
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
        floatingActionButton:
            (_controller.selectedConversationId == null || !isMobile)
                ? FloatingActionButton(
                  onPressed: _showNewConversationDialog,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add_comment),
                  tooltip: 'New Conversation',
                )
                : null,
      ),
    );
  }

  void _showNewConversationDialog() async {
    final petOwners = await _controller.loadPetOwners();

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start New Conversation'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  petOwners.isEmpty
                      ? const Center(child: Text('No pet owners found'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: petOwners.length,
                        itemBuilder: (context, index) {
                          final owner = petOwners[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: MessageUtils.getAvatarColor(
                                owner['full_name'] ?? '',
                              ),
                              child: Text(
                                MessageUtils.getInitials(
                                  owner['full_name'] ?? '',
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(owner['full_name'] ?? 'Unknown'),
                            subtitle: Text(owner['email'] ?? ''),
                            onTap: () {
                              Navigator.pop(context);
                              _controller.createConversation(
                                participantId: owner['id'],
                                name: owner['full_name'],
                              );
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
