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

  final double imageScaleFactor;

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
    this.imageScaleFactor = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isImage = messageType.startsWith('image');
    final bubbleColor = isCurrentUser ? const Color(0xFFE2F7CB) : Colors.white;
    final bubbleAlignment =
    isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final double bubbleMaxWidth = MediaQuery.of(context).size.width * 0.78;

    return Column(
      crossAxisAlignment: bubbleAlignment,
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
          ),
        GestureDetector(
          onLongPress: onLongPress,
          onHorizontalDragUpdate: (details) {
            if ((isCurrentUser && details.delta.dx < -10) ||
                (!isCurrentUser && details.delta.dx > 10)) {
              onReply();
            }
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: bubbleMaxWidth,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 1.5),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: _getBubbleBorderRadius(),
              ),
              child: ClipRRect(
                borderRadius: _getBubbleBorderRadius(),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (replyToMessage != null) _buildReplyHeader(),
                        if (isImage)
                          _buildImageContent(context, bubbleMaxWidth * imageScaleFactor)
                        else
                          _buildTextContent(),
                      ],
                    ),
                    Padding(
                      padding: isImage
                          ? const EdgeInsets.all(5.0)
                          : const EdgeInsets.fromLTRB(0, 0, 8, 6),
                      child: _buildStatusIndicator(isForImage: isImage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BorderRadius _getBubbleBorderRadius() {
    return isCurrentUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(12),
      bottomLeft: Radius.circular(12),
      topRight: Radius.circular(4),
      bottomRight: Radius.circular(12),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(12),
      topLeft: Radius.circular(4),
      bottomLeft: Radius.circular(12),
    );
  }

  Widget _buildReplyHeader() {
    final bool isImageReply = replyToMessage!.contains('image') ||
        replyToMessage!.contains('http');
    final Color replyColor =
    isCurrentUser ? const Color(0xFF5BCB02) : const Color(0xFF3390EC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF7).withOpacity(0.9),
        border: Border(left: BorderSide(color: replyColor, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToSender!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: replyColor,
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


  Widget _buildImageContent(BuildContext context, double scaledImageWidth) {
    final int cacheSize = scaledImageWidth.round();

    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: scaledImageWidth,
            ),
            child: _getImageWidget(cacheSize),
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(int cacheSize) {
    // Shared parameters for Image
    final Image imageWidget = messageType == 'image_local'
        ? Image.file(
      File(message),
      fit: BoxFit.fitWidth,
      cacheWidth: cacheSize,
      gaplessPlayback: true,
    )
        : Image.network(
      message,
      fit: BoxFit.fitWidth,
      cacheWidth: cacheSize,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => _errorPlaceholder(),
    );

    if (messageType == 'image_local') {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Container(color: Colors.black.withOpacity(0.4)),
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child:
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ),
        ],
      );
    }
    return imageWidget;
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
      padding: const EdgeInsets.fromLTRB(6, 28, 8, 6),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 15.5,
          color: Colors.black87,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({bool isForImage = false}) {
    final Color statusColor =
    isForImage ? Colors.white : const Color(0xFFA0A6B1);
    final Color readColor =
    isForImage ? const Color(0xFF6BC7FF) : const Color(0xFF3A9EFF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isEdited)
          const Padding(
            padding: EdgeInsets.only(bottom: 1.5),
            child: Text(
              "изм.",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFA0A6B1),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        if (isCurrentUser)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 3),
              Icon(
                isRead ? Icons.done_all : Icons.done,
                size: 15,
                color: isRead ? readColor : statusColor,
              ),
            ],
          )
      ],
    );
  }

  void _openFullScreenImage(BuildContext context) {
    if (messageType == 'image_local') return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black.withOpacity(animation.value),
          body: SafeArea(
            child: Stack(
              children: [
                PhotoView(
                  imageProvider: NetworkImage(message),
                  backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
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