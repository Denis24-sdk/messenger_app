import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ChatBubble extends StatefulWidget {
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
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double _draggedDistance = 0;
  bool _replyTriggered = false;

  // настройки длины свайпа по сообщению для ответа
  static const double _replySwipeThreshold = 40.0;

  @override
  Widget build(BuildContext context) {
    final bool isImage = widget.messageType.startsWith('image');
    final bubbleColor = widget.isCurrentUser ? const Color(0xFFE2F7CB) : Colors.white;
    final bubbleAlignment =
    widget.isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final double bubbleMaxWidth = MediaQuery.of(context).size.width * 0.78;

    return Column(
      crossAxisAlignment: bubbleAlignment,
      children: [
        if (widget.senderName != null && !widget.isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              widget.senderName!,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF525B67),
              ),
            ),
          ),
        GestureDetector(
          onLongPress: widget.onLongPress,
          onHorizontalDragStart: (details) {
            _draggedDistance = 0;
            _replyTriggered = false;
          },
          onHorizontalDragUpdate: (details) {
            _draggedDistance += details.delta.dx;

            bool isSwipeRight = _draggedDistance > _replySwipeThreshold;
            bool isSwipeLeft = _draggedDistance < -_replySwipeThreshold;

            if (_replyTriggered) return;

            if (!widget.isCurrentUser && isSwipeRight) {
              widget.onReply();
              _replyTriggered = true;
            } else if (widget.isCurrentUser && isSwipeLeft) {
              widget.onReply();
              _replyTriggered = true;
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2.0),
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: _getBubbleBorderRadius(),
            ),
            child: ClipRRect(
              borderRadius: _getBubbleBorderRadius(),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.replyToMessage != null) _buildReplyHeader(),
                      if (isImage)
                        _buildImageContent(context)
                      else
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, widget.isEdited ? 60 : 35, 6),
                          child: _buildTextContent(),
                        ),
                    ],
                  ),
                  Positioned(
                    bottom: isImage ? 5 : 4,
                    right: isImage ? 5 : 8,
                    child: _buildStatusIndicator(isForImage: isImage),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BorderRadius _getBubbleBorderRadius() {
    return widget.isCurrentUser
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      topRight: Radius.circular(4),
      bottomRight: Radius.circular(16),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
      topLeft: Radius.circular(4),
      bottomLeft: Radius.circular(16),
    );
  }

  Widget _buildReplyHeader() {
    final bool isImageReply = widget.replyToMessage!.startsWith('📷');
    final Color replyColor =
    widget.isCurrentUser ? const Color(0xFF5BCB02) : const Color(0xFF3390EC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      margin: const EdgeInsets.fromLTRB(2, 2, 2, 6),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? const Color(0xFFD5F0C2)
            : const Color(0xFFE6E8EA),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: replyColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.replyToSender!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: replyColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isImageReply ? "Изображение" : widget.replyToMessage!,
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
        padding: const EdgeInsets.all(2.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _getImageWidget(),
        ),
      ),
    );
  }

  Widget _getImageWidget() {
    final ImageProvider imageProvider = widget.messageType == 'image_local'
        ? FileImage(File(widget.message))
        : NetworkImage(widget.message);

    if (widget.messageType == 'image_local') {
      return Stack(
        children: [
          Image(image: imageProvider, fit: BoxFit.cover),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
            ),
          ),
        ],
      );
    }

    return Image.network(
      widget.message,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 600,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
    return Text(
      widget.message,
      style: const TextStyle(
        fontSize: 15.5,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildStatusIndicator({bool isForImage = false}) {
    final Color statusColor =
    isForImage ? Colors.white.withOpacity(0.8) : const Color(0xFFA0A6B1);
    final Color readColor =
    isForImage ? const Color(0xFF6BC7FF) : const Color(0xFF3A9EFF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEdited)
          Text(
            "изм. ",
            style: TextStyle(fontSize: 11, color: statusColor),
          ),
        if (widget.isCurrentUser)
          Icon(
            widget.isRead ? Icons.done_all : Icons.done,
            size: 15,
            color: widget.isRead ? readColor : statusColor,
          ),
      ],
    );
  }

  void _openFullScreenImage(BuildContext context) {
    if (widget.messageType == 'image_local') return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.85),
            body: SafeArea(
              child: Stack(
                children: [
                  PhotoView(
                    imageProvider: NetworkImage(widget.message),
                    backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}