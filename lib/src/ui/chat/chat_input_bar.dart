import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../voice/audio_recorder_service.dart';
import '../../voice/press_to_talk_button.dart';
import '../../voice/stt_service.dart';
import '../clawfree_icons.dart';
import '../theme.dart';
import '../voice_input_widget.dart';

/// Callback with the recorded audio file path.
typedef OnAudioFileRecorded = void Function(String filePath);

/// Platform-adaptive input bar with text field, voice button, and send button.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    this.sttService,
    this.audioRecorder,
    this.onAudioRecorded,
    required this.isProcessing,
    required this.onSend,
  });

  final TextEditingController controller;
  final SttService? sttService;
  final AudioRecorderService? audioRecorder;
  final OnAudioFileRecorded? onAudioRecorded;
  final bool isProcessing;
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isListening = false;
  String _interimTranscript = '';
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ClawfreeTheme.isApple ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.85) : Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: Row(
        children: [
          // Press-to-talk (audio file recording) takes priority if available
          if (widget.audioRecorder != null && widget.onAudioRecorded != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PressTalkButton(
                recorder: widget.audioRecorder!,
                onRecorded: widget.onAudioRecorded!,
                onRecordingStateChanged: (recording) {
                  setState(() => _isListening = recording);
                },
                enabled: !widget.isProcessing,
                size: 44,
              ),
            )
          // Fallback to STT widget if no recorder
          else if (widget.sttService != null)
            VoiceInputWidget(
              sttService: widget.sttService!,
              enabled: !widget.isProcessing,
              onTranscript: widget.onSend,
              onListeningChanged: (listening) {
                setState(() {
                  _isListening = listening;
                  if (!listening) _interimTranscript = '';
                });
              },
            ),
          Expanded(child: _buildInputField()),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );

    if (ClawfreeTheme.isApple) {
      return ClipRect(
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: bar),
      );
    }
    return bar;
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.controller.clear();
    widget.onSend(text);
    // Keep keyboard open after sending.
    _focusNode.requestFocus();
  }

  Widget _buildInputField() {
    final hintText = _isListening ? (_interimTranscript.isNotEmpty ? _interimTranscript : 'Listening...') : 'Type or speak a command...';
    final enabled = !widget.isProcessing && !_isListening;

    if (ClawfreeTheme.isApple) {
      return CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        placeholder: hintText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
        enabled: enabled,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.send,
      );
    }

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      enabled: enabled,
      onSubmitted: (_) => _submit(),
      textInputAction: TextInputAction.send,
    );
  }

  Widget _buildSendButton() {
    if (ClawfreeTheme.isApple) {
      return Tooltip(
        message: 'Send message (\u2318Enter)',
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          onPressed: widget.isProcessing ? null : _submit,
          child: Icon(ClawfreeIcons.send, size: 32, color: widget.isProcessing ? CupertinoColors.systemGrey : Theme.of(context).colorScheme.primary),
        ),
      );
    }

    return IconButton.filled(icon: Icon(ClawfreeIcons.send), tooltip: 'Send message (\u2318Enter)', onPressed: widget.isProcessing ? null : _submit);
  }
}
