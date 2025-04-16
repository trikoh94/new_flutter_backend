import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/idea.dart';

class MindMap extends StatefulWidget {
  final List<Idea> ideas;
  final String projectId;
  final Function(String, Offset) onIdeaMoved;
  final Function(Idea) onIdeaTapped;

  const MindMap({
    super.key,
    required this.ideas,
    required this.projectId,
    required this.onIdeaMoved,
    required this.onIdeaTapped,
  });

  @override
  State<MindMap> createState() => _MindMapState();
}

class _MindMapState extends State<MindMap> {
  final TransformationController _transformationController =
      TransformationController();
  final Map<String, Offset> _ideaPositions = {};
  final Map<String, bool> _isDragging = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializePositions();
      _isInitialized = true;
    }
  }

  void _initializePositions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    for (var i = 0; i < widget.ideas.length; i++) {
      final idea = widget.ideas[i];
      final angle = (i / widget.ideas.length) * 2 * math.pi;
      final radius =
          math.min(screenWidth, screenHeight) * 0.3; // 30% of screen size

      // If idea has no position, calculate a new one in a circle
      if (idea.x == 0 && idea.y == 0) {
        _ideaPositions[idea.id] = Offset(
          screenWidth / 2 + radius * math.cos(angle),
          screenHeight / 2 + radius * math.sin(angle),
        );
      } else {
        _ideaPositions[idea.id] = Offset(idea.x, idea.y);
      }
      _isDragging[idea.id] = false;
    }
  }

  @override
  void didUpdateWidget(MindMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ideas != oldWidget.ideas) {
      _initializePositions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 4.0,
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: ConnectionPainter(
                  ideas: widget.ideas,
                  positions: _ideaPositions,
                ),
              ),
              ...widget.ideas.map((idea) {
                final position =
                    _ideaPositions[idea.id] ?? Offset(idea.x, idea.y);
                final isDragging = _isDragging[idea.id] ?? false;
                return Positioned(
                  left: position.dx - 100,
                  top: position.dy - 40,
                  child: GestureDetector(
                    onPanStart: (_) {
                      setState(() {
                        _isDragging[idea.id] = true;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _ideaPositions[idea.id] = Offset(
                          position.dx + details.delta.dx,
                          position.dy + details.delta.dy,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isDragging[idea.id] = false;
                      });
                      widget.onIdeaMoved(idea.id, _ideaPositions[idea.id]!);
                    },
                    onTap: () => widget.onIdeaTapped(idea),
                    child: Container(
                      width: 200,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDragging ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDragging
                              ? Colors.blue.shade200
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Drag to move',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            idea.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (idea.description.isNotEmpty)
                            Text(
                              idea.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoomIn',
                onPressed: () {
                  final scale =
                      _transformationController.value.getMaxScaleOnAxis();
                  _transformationController.value = Matrix4.identity()
                    ..scale(scale + 0.5);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoomOut',
                onPressed: () {
                  final scale =
                      _transformationController.value.getMaxScaleOnAxis();
                  _transformationController.value = Matrix4.identity()
                    ..scale(scale - 0.5);
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'reset',
                onPressed: () {
                  _transformationController.value = Matrix4.identity();
                },
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final List<Idea> ideas;
  final Map<String, Offset> positions;

  ConnectionPainter({
    required this.ideas,
    required this.positions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final idea in ideas) {
      final startPos = positions[idea.id];
      if (startPos == null) continue;

      for (final connectedId in idea.connectedIdeas) {
        final endPos = positions[connectedId];
        if (endPos == null) continue;

        final path = Path();
        path.moveTo(startPos.dx, startPos.dy);

        final controlPoint1 = Offset(
          startPos.dx + (endPos.dx - startPos.dx) * 0.25,
          startPos.dy,
        );
        final controlPoint2 = Offset(
          endPos.dx - (endPos.dx - startPos.dx) * 0.25,
          endPos.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          endPos.dx,
          endPos.dy,
        );

        // Draw arrow
        final arrowPath = Path();
        final arrowSize = 10.0;
        final angle = math.atan2(
            endPos.dy - controlPoint2.dy, endPos.dx - controlPoint2.dx);

        arrowPath.moveTo(endPos.dx, endPos.dy);
        arrowPath.lineTo(
          endPos.dx - arrowSize * math.cos(angle - math.pi / 6),
          endPos.dy - arrowSize * math.sin(angle - math.pi / 6),
        );
        arrowPath.moveTo(endPos.dx, endPos.dy);
        arrowPath.lineTo(
          endPos.dx - arrowSize * math.cos(angle + math.pi / 6),
          endPos.dy - arrowSize * math.sin(angle + math.pi / 6),
        );

        canvas.drawPath(path, paint);
        canvas.drawPath(arrowPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
