import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';

class ListingReference extends StatefulWidget {
  const ListingReference({super.key, required this.code, this.compact = false});

  final String? code;
  final bool compact;

  @override
  State<ListingReference> createState() => _ListingReferenceState();
}

class _ListingReferenceState extends State<ListingReference>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _resetTimer;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.92,
      upperBound: 1.12,
      value: 1,
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final code = widget.code?.trim();
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    unawaited(
      _controller.forward(from: 0.92).then((_) {
        if (mounted) _controller.animateTo(1, curve: Curves.easeOutBack);
      }),
    );
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code?.trim();
    if (code == null || code.isEmpty) return const SizedBox.shrink();

    final colors = context.chezMoiColors;
    final fontSize = widget.compact ? 11.5 : 12.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: fontSize,
              height: 1.2,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 4),
        ScaleTransition(
          scale: _controller,
          child: SizedBox(
            width: widget.compact ? 26 : 30,
            height: widget.compact ? 26 : 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tooltip: _copied ? 'Copié' : 'Copier la référence',
              onPressed: _copy,
              icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: widget.compact ? 14 : 16,
                color: _copied ? const Color(0xFF16A34A) : colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
