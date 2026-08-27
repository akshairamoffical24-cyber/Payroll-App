import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnimatedGpsRadar extends StatefulWidget {
  final double size;
  final Color radarColor;
  final bool isSuccess;
  final bool isError;
  final String statusText;
  final String subText;

  const AnimatedGpsRadar({
    super.key,
    this.size = 200,
    this.radarColor = AppColors.primary,
    this.isSuccess = false,
    this.isError = false,
    required this.statusText,
    required this.subText,
  });

  @override
  State<AnimatedGpsRadar> createState() => _AnimatedGpsRadarState();
}

class _AnimatedGpsRadarState extends State<AnimatedGpsRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isSuccess
        ? AppColors.present
        : (widget.isError ? AppColors.absent : widget.radarColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing concentric ripple waves
              if (!widget.isSuccess && !widget.isError)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _RadarRipplePainter(
                        progress: _controller.value,
                        color: effectiveColor,
                      ),
                    );
                  },
                ),

              // Geofence Circle Boundary Indicator
              Container(
                width: widget.size * 0.78,
                height: widget.size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: effectiveColor.withOpacity(0.4),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  ),
                  color: effectiveColor.withOpacity(0.06),
                ),
              ),

              // Center Target / Beacon Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isSuccess
                      ? Icons.check_rounded
                      : (widget.isError
                          ? Icons.location_off_rounded
                          : Icons.satellite_alt_rounded),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: effectiveColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.subText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i / 3)) % 1.0;
      final radius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.4;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarRipplePainter oldDelegate) => true;
}
