import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/message-widgets/empty_states.dart';
import 'package:petpal/message-widgets/utils/message_utils.dart';

class VetConversationListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conversations;
  final String? selectedId;
  final Function(String, String) onSelect;
  final VoidCallback onNewConversation;

  const VetConversationListWidget({
    Key? key,
    required this.conversations,
    this.selectedId,
    required this.onSelect,
    required this.onNewConversation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color.fromARGB(255, 37, 45, 50),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Pet Owners',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                ),
                onPressed: onNewConversation,
                tooltip: 'New Conversation',
                iconSize: 20,
              ),
            ],
          ),
        ),

        Expanded(
          child:
              conversations.isEmpty
                  ? EmptyConversationsView(onNewConversation: onNewConversation)
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
                            backgroundColor: MessageUtils.getAvatarColor(
                              participantName,
                            ),
                            child: Text(
                              MessageUtils.getInitials(participantName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
                          subtitle: Text(
                            lastMessage,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
