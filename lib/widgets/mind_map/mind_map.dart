import 'package:flutter/material.dart';
import '../../models/idea.dart';

class MindMap extends StatelessWidget {
  final List<Idea> ideas;
  final TransformationController transformationController;
  final Function(Idea) onIdeaTap;

  const MindMap({
    super.key,
    required this.ideas,
    required this.transformationController,
    required this.onIdeaTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: transformationController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.5,
      maxScale: 4.0,
      child: Stack(
        children: [
          // Draw connections between ideas
          CustomPaint(
            size: Size.infinite,
            painter: ConnectionPainter(ideas: ideas),
          ),
          // Draw idea nodes
          ...ideas.map((idea) => Positioned(
                left: idea.x,
                top: idea.y,
                child: GestureDetector(
                  onTap: () => onIdeaTap(idea),
                  child: IdeaNode(idea: idea),
                ),
              )),
        ],
      ),
    );
  }
}

class ConnectionPainter extends CustomPainter {
  final List<Idea> ideas;

  ConnectionPainter({required this.ideas});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2;

    for (final idea in ideas) {
      for (final connectedId in idea.connectedIdeas) {
        final connectedIdea = ideas.firstWhere(
          (i) => i.id == connectedId,
          orElse: () => idea,
        );

        canvas.drawLine(
          Offset(idea.x + 50, idea.y + 25),
          Offset(connectedIdea.x + 50, connectedIdea.y + 25),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class IdeaNode extends StatelessWidget {
  final Idea idea;

  const IdeaNode({
    super.key,
    required this.idea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          idea.title,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
