import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;

  const GradientBackground({
    super.key, 
    required this.child, 
    this.appBar, 
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Professional Dark Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // Deep Dark Blue
                  Color(0xFF203A43),
                  Color(0xFF2C5364), // Teal-ish Grey
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}
