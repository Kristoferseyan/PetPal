import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/message-widgets/utils/message_utils.dart';

class MessageListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String currentUserId;

  const MessageListWidget({
    Key? key,
    required this.messages,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _previousMessages = [];
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      const threshold = 200.0;

      if (currentScroll < maxScroll - threshold && !_showScrollButton) {
        setState(() => _showScrollButton = true);
      } else if (currentScroll >= maxScroll - threshold && _showScrollButton) {
        setState(() => _showScrollButton = false);
      }
    }
  }

  @override
  void didUpdateWidget(MessageListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length > _previousMessages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    _previousMessages = List.from(widget.messages);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? currentDay;

    final sortedMessages = List<Map<String, dynamic>>.from(widget.messages);
    sortedMessages.sort((a, b) {
      return DateTime.parse(
        a['created_at'],
      ).compareTo(DateTime.parse(b['created_at']));
    });

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

          reverse: false,
          itemCount: sortedMessages.length,
          itemBuilder: (context, index) {
            final message = sortedMessages[index];
            final isMe = message['sender_id'] == widget.currentUserId;
            final messageTime = DateTime.parse(message['created_at']);
            final isPending = message['is_pending'] == true;

            final String messageDay = DateFormat(
              'yyyy-MM-dd',
            ).format(messageTime);

            final bool shouldShowDate = currentDay != messageDay;
            if (shouldShowDate) {
              currentDay = messageDay;
            }

            return Column(
              children: [
                if (shouldShowDate)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getFormattedMessageDate(messageTime),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isMe
                              ? AppColors.primary
                              : const Color.fromARGB(255, 55, 65, 70),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            isMe
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                        bottomRight:
                            isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                      ),

                      boxShadow:
                          isPending
                              ? []
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Opacity(
                      opacity: isPending ? 0.7 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['content'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(messageTime),
                                style: TextStyle(
                                  color:
                                      isMe
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  isPending
                                      ? Icons.access_time_rounded
                                      : Icons.check_circle,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          bottom: _showScrollButton ? 16 : -60,
          right: 16,
          child: FloatingActionButton.small(
            backgroundColor: AppColors.primary.withOpacity(0.8),
            onPressed: _scrollToBottom,
            child: const Icon(Icons.arrow_downward, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _getFormattedMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}
