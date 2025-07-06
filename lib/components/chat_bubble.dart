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
    return Column(
        crossAxisAlignment:
        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
        if (senderName != null && !isCurrentUser)
    Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
      child: Text(
        senderName!,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF525B67),
        ),
      ),
      GestureDetector(
        onLongPress: onLongPress,
        onHorizontalDragUpdate: (details) {
          if (isCurrentUser && details.delta.dx < -10 ||
              !isCurrentUser && details.delta.dx > 10) {
            onReply();
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 1.5),
            decoration: BoxDecoration(
              color: isCurrentUser ? const Color(0xFFE2F7CB) : Colors.white,
              borderRadius: _getBorderRadius(),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 1.5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replyToMessage != null) _buildReplyHeader(),
                if (messageType.startsWith('image'))
                  _buildImageContent(context)
                else
                  _buildTextContent(),
              ],
            ),
          ),
        ),
      ),
      ],
    );
  }

  BorderRadius _getBorderRadius() {
    return isCurrentUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(12),
      bottomLeft: Radius.circular(12),
      topRight: Radius.circular(2),
      bottomRight: Radius.circular(12),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(12),
      topLeft: Radius.circular(2),
      bottomLeft: Radius.circular(12),
    );
  }

  Widget _buildReplyHeader() {
    final bool isImageReply = replyToMessage!.contains('image') ||
        replyToMessage!.contains('http');

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF7).withOpacity(0.9),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? const Color(0xFF5BCB02) : const Color(0xFF3390EC),
            width: 2.5,
          ),
        ),
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
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: isCurrentUser ? const Color(0xFF5BCB02) : const Color(0xFF3390EC),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isImageReply ? "Изображение" : replyToMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5E6369),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _getImageWidget(context),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildStatusIndicator(isForImage: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(BuildContext context) {
    if (messageType == 'image_local') {
      return Image.file(
        File(message),
        fit: BoxFit.cover,
        cacheWidth: (MediaQuery.of(context).size.width * 0.5).toInt(),
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          if (frame == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
      );
    }

    return Image.network(
      message,
      fit: BoxFit.cover,
      cacheWidth: (MediaQuery.of(context).size.width * 0.5).toInt(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        if (frame == null) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return child;
      },
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15.5,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 5),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({bool isForImage = false}) {
    final statusColor = isForImage
        ? Colors.white
        : const Color(0xFFA0A6B1);

    final readColor = isForImage
        ? const Color(0xFF6BC7FF)
        : const Color(0xFF3A9EFF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isEdited)
          Padding(
            padding: const EdgeInsets.only(bottom: 1.5),
            child: Text(
              "изм.",
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        if (isCurrentUser) ...[
          const SizedBox(width: 3),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 15,
            color: isRead ? readColor : statusColor,
          ),
        ]
      ],
    );
  }

  void _openFullScreenImage(BuildContext context) {
    if (messageType == 'image_local') return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                PhotoView(
                  imageProvider: NetworkImage(message),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        value: event?.expectedTotalBytes != null
                            ? (event!.cumulativeBytesLoaded / event.expectedTotalBytes!)
                            : null,
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Material(
                    color: Colors.transparent,
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
      ),
    );
  }
}