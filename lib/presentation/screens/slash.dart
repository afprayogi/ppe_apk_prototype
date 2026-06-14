import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Animasi lengkungan (bergerak halus)
    final animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    final topAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.1)).animate(animation);
    final bottomAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.1)).animate(animation);
    
    // Animasi tombol (berdenyut/pulsing)
    final scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(animation);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Lengkungan Atas
          SlideTransition(
            position: topAnim,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
                ),
              ),
            ),
          ),

          // Lengkungan Bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: bottomAnim,
              child: ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
                  ),
                ),
              ),
            ),
          ),

          // Konten Utama
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF2E7D32), width: 3)),
                  child: const Center(child: Text("LOGO VIVATPASS", style: TextStyle(fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Scan. Detect. Protect.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF002244)),
                ),
                const SizedBox(height: 40),

                // Tombol dengan efek Denyut + Tekan
                ScaleTransition(
                  scale: scaleAnim,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) => setState(() => _isPressed = false),
                    onTap: () => print("Navigasi"),
                    child: AnimatedScale(
                      scale: _isPressed ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 280, height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 5))],
                        ),
                        child: const Center(
                          child: Text("GO START", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 50);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 50);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}