import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/event_model.dart';

class WeeklyActivityChart extends StatelessWidget {
  final List<WeeklyActivityData> data;

  const WeeklyActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Activity Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: ChartPainter(data: data),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<WeeklyActivityData> data;

  ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    final maxValue = data
        .fold<int>(0, (max, item) => item.value > max ? item.value : max)
        .toDouble();
    final minValue = 0.0;
    final rangeValue = maxValue - minValue;

    final width = size.width;
    final height = size.height;
    final pointSpacing = width / (data.length - 1);
    final topPadding = 10.0;
    final bottomPadding = 20.0;

    final yLabels = [40, 30, 20, 10, 0];
    for (int i = 0; i < yLabels.length; i++) {
      final y =
          height -
          bottomPadding -
          (yLabels[i] / 40) * (height - bottomPadding - topPadding);

      textPaint.text = TextSpan(
        text: '${yLabels[i]}',
        style: const TextStyle(color: AppColors.textLight, fontSize: 11),
      );
      textPaint.layout();

      final textX = -textPaint.width - 6;
      final textY = y - textPaint.height / 2;

      textPaint.paint(canvas, Offset(textX, textY));

      if (i > 0) {
        canvas.drawLine(
          Offset(0, y),
          Offset(width, y),
          Paint()
            ..color = Colors.grey.withOpacity(0.1)
            ..strokeWidth = 1,
        );
      }
    }

    // Calculate points
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final x = i * pointSpacing;
      final normalizedValue = (data[i].value - minValue) / rangeValue;
      final y =
          height -
          bottomPadding -
          normalizedValue * (height - bottomPadding - topPadding);
      points.add(Offset(x, y));
    }

    // Draw filled area under curve
    final path = Path();
    path.moveTo(points[0].dx, height - bottomPadding);
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final controlX = (points[i - 1].dx + points[i].dx) / 2;
        path.quadraticBezierTo(
          controlX,
          points[i - 1].dy,
          points[i].dx,
          points[i].dy,
        );
      }
    }
    path.lineTo(points.last.dx, height - bottomPadding);
    path.close();
    canvas.drawPath(path, paint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final controlX = (points[i - 1].dx + points[i].dx) / 2;
      linePath.quadraticBezierTo(
        controlX,
        points[i - 1].dy,
        points[i].dx,
        points[i].dy,
      );
    }
    canvas.drawPath(linePath, linePaint);

    // Draw points
    for (var point in points) {
      canvas.drawCircle(point, 3, Paint()..color = AppColors.primary);
    }

    // Draw X-axis labels
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 0; i < days.length; i++) {
      final x = i * pointSpacing;
      textPaint.text = TextSpan(
        text: days[i],
        style: const TextStyle(color: AppColors.textLight, fontSize: 11),
      );
      textPaint.layout();
      textPaint.paint(canvas, Offset(x - textPaint.width / 2, height - 8));
    }
  }

  @override
  bool shouldRepaint(ChartPainter oldDelegate) => false;
}
