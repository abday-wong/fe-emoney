import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool light;
  final bool withText;

  const AppLogo(
      {super.key, this.size = 56, this.light = false, this.withText = false});

  @override
  Widget build(BuildContext context) {
    const fontFamily = 'PlusJakartaSans';

    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: PersonaLogoPainter(
          primaryColor: AppColors.primary,
          accentColor: AppColors.primaryDark,
        ),
      ),
    );

    if (!withText) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doran',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w900,
                color: light ? Colors.white : AppColors.ink,
                letterSpacing: -0.3,
                height: 1.05,
              ),
            ),
            Text(
              'PAY',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: size * 0.205,
                fontWeight: FontWeight.w900,
                color:
                    light ? Colors.white.withOpacity(0.85) : AppColors.primary,
                letterSpacing: 1.5,
                height: 1.05,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PersonaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  PersonaLogoPainter({required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Solid black background shield (slanted jagged polygon shape)
    final bgPath = Path();
    bgPath.moveTo(w * 0.1, h * 0.2);
    bgPath.lineTo(w * 0.9, h * 0.1);
    bgPath.lineTo(w * 0.85, h * 0.85);
    bgPath.lineTo(w * 0.2, h * 0.9);
    bgPath.close();
    paint.color = Colors.black;
    canvas.drawPath(bgPath, paint);

    // Primary red slanted/jagged star
    final starPath = Path();
    starPath.moveTo(w * 0.5, h * 0.15); // Top
    starPath.lineTo(w * 0.62, h * 0.40); // Top-right inner
    starPath.lineTo(w * 0.88, h * 0.35); // Right
    starPath.lineTo(w * 0.70, h * 0.58); // Bottom-right inner
    starPath.lineTo(w * 0.80, h * 0.85); // Bottom-right
    starPath.lineTo(w * 0.5, h * 0.70); // Bottom inner
    starPath.lineTo(w * 0.20, h * 0.85); // Bottom-left
    starPath.lineTo(w * 0.30, h * 0.58); // Bottom-left inner
    starPath.lineTo(w * 0.12, h * 0.35); // Left
    starPath.lineTo(w * 0.38, h * 0.40); // Top-left inner
    starPath.close();

    paint.color = primaryColor;
    canvas.drawPath(starPath, paint);

    // Sharp white geometric stripe slicing through
    final stripePath = Path();
    stripePath.moveTo(w * 0.25, h * 0.45);
    stripePath.lineTo(w * 0.75, h * 0.30);
    stripePath.lineTo(w * 0.78, h * 0.38);
    stripePath.lineTo(w * 0.28, h * 0.53);
    stripePath.close();
    paint.color = Colors.white;
    canvas.drawPath(stripePath, paint);

    // Sharp black wallet symbol
    final walletPath = Path();
    walletPath.moveTo(w * 0.35, h * 0.42);
    walletPath.lineTo(w * 0.65, h * 0.38);
    walletPath.lineTo(w * 0.62, h * 0.68);
    walletPath.lineTo(w * 0.38, h * 0.72);
    walletPath.close();
    paint.color = Colors.black;
    canvas.drawPath(walletPath, paint);

    final walletInner = Path();
    walletInner.moveTo(w * 0.38, h * 0.45);
    walletInner.lineTo(w * 0.62, h * 0.41);
    walletInner.lineTo(w * 0.59, h * 0.65);
    walletInner.lineTo(w * 0.41, h * 0.69);
    walletInner.close();
    paint.color = Colors.white;
    canvas.drawPath(walletInner, paint);

    // Wallet card slot in red
    final slotPath = Path();
    slotPath.moveTo(w * 0.42, h * 0.50);
    slotPath.lineTo(w * 0.58, h * 0.48);
    slotPath.lineTo(w * 0.57, h * 0.54);
    slotPath.lineTo(w * 0.43, h * 0.56);
    slotPath.close();
    paint.color = primaryColor;
    canvas.drawPath(slotPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
