import 'package:flutter/material.dart';
import 'package:petpal/message-widgets/controller/petOwner_messaging_controller.dart';
import 'package:petpal/message-widgets/empty_states.dart';
import 'package:petpal/message-widgets/message_input.dart';
import 'package:petpal/message-widgets/message_list.dart';
import 'package:petpal/utils/colors.dart';

class PetOwnerMessagePage extends StatefulWidget {
  const PetOwnerMessagePage({Key? key}) : super(key: key);

  @override
  State<PetOwnerMessagePage> createState() => _PetOwnerMessagePageState();
}

class _PetOwnerMessagePageState extends State<PetOwnerMessagePage> {
  final PetOwnerMessagingController _controller = PetOwnerMessagingController();

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
          iconTheme: const IconThemeData(color: Colors.white),
          title: Row(
            children: [
              Icon(
                Icons.medical_services_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _controller.selectedConversationId != null && isMobile
                    ? _controller.selectedParticipantName ?? 'Chat'
                    : 'Clinic Messages',
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
                    ? PetOwnerConversationList(
                      conversations: _controller.conversations,
                      selectedId: _controller.selectedConversationId,
                      onSelect: _controller.selectConversation,
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
                      child: PetOwnerConversationList(
                        conversations: _controller.conversations,
                        selectedId: _controller.selectedConversationId,
                        onSelect: _controller.selectConversation,
                      ),
                    ),

                    Container(width: 1, color: Colors.grey[800]),

                    Expanded(
                      child:
                          _controller.selectedConversationId == null
                              ? const PetOwnerNoConversationSelectedView()
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
      ),
    );
  }
}

class PetOwnerConversationList extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final String? selectedId;
  final Function(String, String) onSelect;

  const PetOwnerConversationList({
    Key? key,
    required this.conversations,
    this.selectedId,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color.fromARGB(255, 37, 45, 50),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Clinic Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child:
              conversations.isEmpty
                  ? const PetOwnerEmptyConversationsView()
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final isSelected = conversation['id'] == selectedId;
                      final participantName =
                          conversation['participantName'] ?? 'Unknown';
                      final lastMessage =
                          conversation['lastMessage'] ?? 'No messages yet';

                      final isVetClinic =
                          conversation['participantRole'] == 'vet_clinic';

                      return Container(
                        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withOpacity(0.2)
                                  : const Color.fromARGB(255, 55, 65, 70),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isSelected
                                  ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                isVetClinic
                                    ? AppColors.primary
                                    : const Color.fromARGB(255, 100, 100, 100),
                            child: Icon(
                              isVetClinic
                                  ? Icons.medical_services
                                  : Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            participantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isVetClinic
                                              ? AppColors.primary.withOpacity(
                                                0.2,
                                              )
                                              : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isVetClinic ? 'Clinic' : 'Staff',
                                      style: TextStyle(
                                        color:
                                            isVetClinic
                                                ? AppColors.primary
                                                : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastMessage,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onTap:
                              () =>
                                  onSelect(conversation['id'], participantName),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class PetOwnerEmptyConversationsView extends StatelessWidget {
  const PetOwnerEmptyConversationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your messages from clinics will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class PetOwnerNoConversationSelectedView extends StatelessWidget {
  const PetOwnerNoConversationSelectedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 72, color: Colors.grey[600]),
          const SizedBox(height: 24),
          const Text(
            'Select a conversation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a clinic conversation from the list',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
