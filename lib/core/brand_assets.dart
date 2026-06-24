import 'package:flutter/material.dart';

/// ChezMoi brand asset paths. The resolver tries candidates in priority order.
class BrandAssets {
  BrandAssets._();

  static const iconCandidates = ['assets/images/newlogo.png'];

  static const logoCandidates = ['assets/images/newlogo.png'];
}

/// Displays the first available asset from [candidates], or [fallback] if none load.
class BrandAssetImage extends StatefulWidget {
  const BrandAssetImage({
    super.key,
    required this.candidates,
    required this.fallback,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final List<String> candidates;
  final Widget fallback;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  State<BrandAssetImage> createState() => _BrandAssetImageState();
}

class _BrandAssetImageState extends State<BrandAssetImage> {
  int _candidateIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_candidateIndex >= widget.candidates.length) {
      return widget.fallback;
    }

    final path = widget.candidates[_candidateIndex];

    return Image.asset(
      path,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_candidateIndex + 1 < widget.candidates.length) {
            setState(() => _candidateIndex += 1);
          } else if (_candidateIndex != widget.candidates.length) {
            setState(() => _candidateIndex = widget.candidates.length);
          }
        });
        return widget.fallback;
      },
    );
  }
}
