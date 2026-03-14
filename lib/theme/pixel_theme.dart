import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PixelColors {
  PixelColors._();

  // Primary (아이콘 추출)
  static const gridBorderDark = Color(0xFF344A7E);
  static const gridBorderLight = Color(0xFF5B7BBF);
  static const cellBackground = Color(0xFF9FC2E8);
  static const cellBackgroundAlt = Color(0xFFB5D4F0);
  static const scaffoldBg = Color(0xFF6B8CCE);
  static const numberFixed = Color(0xFF1A2744);
  static const numberUser = Color(0xFF1A56DB);
  static const accentOrange = Color(0xFFE8A030);
  static const pixelBlack = Color(0xFF202020);

  // State Colors
  static const cellSelected = Color(0xFFFFE082);
  static const cellRelated = Color(0xFF7FAAD8);
  static const cellSameNumber = Color(0xFFD5F5D0);
  static const cellWrong = Color(0xFFEF5350);
  static const cellWrongBg = Color(0xFFFFCDD2);
  static const buttonDisabled = Color(0xFF8EA8CC);
  static const memoActive = Color(0xFF4ECDC4);
  static const memoActiveBg = Color(0xFFD0F5F0);
  static const hintBg = Color(0xFFFFF0D0);
}

class PixelTextStyles {
  PixelTextStyles._();

  static TextStyle base({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = PixelColors.numberFixed,
    double? height,
  }) {
    return GoogleFonts.dotGothic16(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static final TextStyle title = base(fontSize: 40, fontWeight: FontWeight.bold);
  static final TextStyle label = base(fontSize: 14, fontWeight: FontWeight.w600, color: PixelColors.cellBackgroundAlt);
  static final TextStyle timer = base(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white);
  static final TextStyle chip = base(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white);
}

List<BoxShadow> pixelShadow({Color? color, Offset offset = const Offset(3, 3)}) {
  return [
    BoxShadow(
      color: color ?? PixelColors.pixelBlack.withValues(alpha: 0.4),
      offset: offset,
      blurRadius: 0,
    ),
  ];
}

BoxDecoration pixelBoxDecoration({
  Color color = PixelColors.cellBackgroundAlt,
  Color borderColor = PixelColors.gridBorderDark,
  double borderWidth = 3,
  bool hasShadow = true,
}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: borderColor, width: borderWidth),
    boxShadow: hasShadow ? pixelShadow() : null,
  );
}

/// 픽셀 스타일 버튼 (직각 + 그림자 + 눌림 효과)
class PixelButton extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final double shadowOffset;

  const PixelButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.child,
    this.shadowOffset = 3.0,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = widget.shadowOffset;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        transform: _isPressed
            ? Matrix4.translationValues(offset, offset, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: PixelColors.pixelBlack, width: 2),
          boxShadow: _isPressed
              ? null
              : pixelShadow(offset: Offset(offset, offset)),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
