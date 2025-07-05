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
    required this.onLongPress,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    bool isImage = messageType.startsWith('image');

    return GestureDetector(
      onLongPress: onLongPress,
      onHorizontalDragUpdate: (details) {
        if (isCurrentUser ? details.delta.dx < -10 : details.delta.dx > 10) {
          onReply();
        }
      },
      onTap: isImage ? () => _openFullScreenImage(context) : null,
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
    );
  }


  void _openFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: PhotoView(
                  imageProvider: _getImageProvider(),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (messageType == 'image_local') {
      return FileImage(File(message));
    } else {
      return NetworkImage(message);
    }
  }

  Widget _buildImageContent(BuildContext context) {
    Widget imageWidget;
    if (messageType == 'image_local') {
      imageWidget = Image.file(File(message), fit: BoxFit.cover);
    }
    else {
      imageWidget = Image.network(
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

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: MediaQuery.of(context).size.width * 0.8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: imageWidget, // Просто показываем картинку, без Stack и индикатора
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replyToMessage != null && replyToSender != null) _buildReplyBox(),
        Text(
          message,
          style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEdited)
              Text(
                "изм. ",
                style: TextStyle(
                  fontSize: 10,
                  color: (isCurrentUser ? Colors.white : Colors.black).withOpacity(0.6),
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