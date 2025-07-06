import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String messageType;
  final bool isCurrentUser;
  final bool isRead;
  final bool isEdited;
  final String? replyToMessage;
  final String? replyToSender;
  final String? senderName;
  final VoidCallback onLongPress;
  final VoidCallback onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.messageType,
    required this.isCurrentUser,
    required this.isRead,
    this.isEdited = false,
    this.replyToMessage,
    this.replyToSender,
    this.senderName,
    required this.onLongPress,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    bool isImage = messageType.startsWith('image');

    return Column(
      crossAxisAlignment:
      isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (senderName != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              senderName!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        GestureDetector(
          onLongPress: onLongPress,
          onHorizontalDragUpdate: (details) {
            if (isCurrentUser ? details.delta.dx < -10 : details.delta.dx > 10) {
              onReply();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: isImage
                ? const EdgeInsets.all(3)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: isImage ? _buildImageContent(context) : _buildTextContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: MediaQuery.of(context).size.width * 0.8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: _getImageWidget(),
        ),
      ),
    );
  }

  Widget _getImageWidget() {
    if (messageType == 'image_local') {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.file(File(message),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
        ],
      );
    }

    return Image.network(
      message,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.error, color: Colors.red),
    );
  }

  ImageProvider _getImageProvider() {
    if (messageType == 'image_local') {
      return FileImage(File(message));
    }
    return NetworkImage(message);
  }

  void _openFullScreenImage(BuildContext context) {
    if(messageType == 'image_local') return;

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: _getImageProvider(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    )));
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyToMessage != null && replyToSender != null) _buildReplyBox(),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message,
                style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (isEdited)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      "изм.",
                      style: TextStyle(
                        fontSize: 10,
                        color: (isCurrentUser ? Colors.white : Colors.black).withOpacity(0.6),
                      ),
                    ),
                  ),
                if (isCurrentUser)
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: isRead
                        ? Colors.blue.shade300
                        : (isCurrentUser ? Colors.white : Colors.black).withOpacity(0.6),
                  ),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildReplyBox() {
    final isImageReply = replyToMessage!.startsWith('http') || replyToMessage! == '📷 Изображение';
    return IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isCurrentUser ? Colors.white : Colors.black).withOpacity(0.2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              replyToSender!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.white70 : Colors.green,
                fontSize: 12,
              ),
            ),
            Text(
              isImageReply ? "📷 Изображение" : replyToMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}