import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger_flutter/main.dart';
import 'package:photo_view/photo_view.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final String messageType;
  final bool isCurrentUser;
  final Timestamp timestamp;
  final bool isRead;
  final bool isEdited;
  final String? replyToMessage;
  final String? replyToSender;
  final String? senderName;
  final double? aspectRatio;
  final VoidCallback onLongPress;
  final VoidCallback onReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.messageType,
    required this.isCurrentUser,
    required this.timestamp,
    required this.isRead,
    this.isEdited = false,
    this.replyToMessage,
    this.replyToSender,
    this.senderName,
    this.aspectRatio,
    required this.onLongPress,
    required this.onReply,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double _dragOffset = 0.0;
  bool _replyTriggered = false;

  static const double _replySwipeThreshold = 60.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_replyTriggered) return;
    setState(() => _dragOffset += details.delta.dx);
    if (_dragOffset.abs() > _replySwipeThreshold) {
      widget.onReply();
      _replyTriggered = true;
    }
  }

  void _onDragEnd(DragEndDetails details) => setState(() => _dragOffset = 0);
  void _onDragStart(DragStartDetails details) => _replyTriggered = false;

  @override
  Widget build(BuildContext context) {
    final currentUserBubbleColor = const Color(0xFF005C4B);
    final otherUserBubbleColor = AppColors.card;
    final bubbleColor = widget.isCurrentUser
        ? currentUserBubbleColor
        : otherUserBubbleColor;
    final bubbleAlignment = widget.isCurrentUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final double bubbleMaxWidth = MediaQuery.of(context).size.width * 0.78;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Stack(
          alignment: widget.isCurrentUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: (_dragOffset.abs() > 20) ? 1.0 : 0.0,
              child: Icon(Icons.reply, color: AppColors.textSecondary),
            ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Column(
                crossAxisAlignment: bubbleAlignment,
                children: [
                  if (widget.senderName != null && !widget.isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                      child: Text(
                        widget.senderName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onLongPress: widget.onLongPress,
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: _getBubbleBorderRadius(),
                      ),
                      child: _buildBubbleContent(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildBubbleContent(BuildContext context) {
    final bool isImage = widget.messageType.startsWith('image');
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.replyToMessage != null) _buildReplyHeader(),
          isImage ? _buildImageContent(context) : _buildTextLayout(),
        ],
      ),
    );
  }

  Widget _buildReplyHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.replyToSender!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              widget.replyToMessage!.startsWith('📷')
                  ? "Изображение"
                  : widget.replyToMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenImage(context),
      child: ClipRRect(
        borderRadius: (widget.replyToMessage != null)
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : _getBubbleBorderRadius(),
        child: Container(
          padding: const EdgeInsets.all(3.0),
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: _getImageWidget(),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: _buildStatusIndicator(isForImage: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 15.5,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: _buildStatusIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _getImageWidget() {
    if (widget.messageType == 'image_local') {
      return AspectRatio(
        aspectRatio: widget.aspectRatio ?? 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.message), fit: BoxFit.cover),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return CachedNetworkImage(
      imageUrl: widget.message,
      memCacheWidth: (300 * dpr).round(),
      fit: BoxFit.cover,
      placeholder: (context, url) => AspectRatio(
        aspectRatio: widget.aspectRatio ?? 16 / 9,
        child: Container(
          color: AppColors.card,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.0,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => AspectRatio(
        aspectRatio: widget.aspectRatio ?? 1.0,
        child: _errorPlaceholder(),
      ),
    );
  }

  Widget _errorPlaceholder() => Container(
    color: AppColors.card,
    child: Center(
      child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 36),
    ),
  );

  Widget _buildStatusIndicator({bool isForImage = false}) {
    final statusColor = AppColors.textSecondary.withOpacity(
      isForImage ? 0.9 : 0.8,
    );
    final readColor = AppColors.accent;
    final String formattedTime = DateFormat(
      'HH:mm',
    ).format(widget.timestamp.toDate());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text(
              "изм.",
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Text(formattedTime, style: TextStyle(fontSize: 12, color: statusColor)),
        if (widget.isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              widget.isRead ? Icons.done_all : Icons.done,
              size: 16,
              color: widget.isRead ? readColor : statusColor,
            ),
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
            backgroundColor: Colors.black.withOpacity(0.9),
            body: SafeArea(
              child: Stack(
                children: [
                  PhotoView(
                    imageProvider: CachedNetworkImageProvider(widget.message),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    loadingBuilder: (context, event) => const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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
