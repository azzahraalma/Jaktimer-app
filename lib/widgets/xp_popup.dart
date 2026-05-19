import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class XpPopup extends StatefulWidget {
  final int xp;
  final String label;
  final VoidCallback onDismiss;

  const XpPopup({
    super.key,
    required this.xp,
    required this.label,
    required this.onDismiss,
  });

  @override
  State<XpPopup> createState() => _XpPopupState();
}

class _XpPopupState extends State<XpPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _playSound();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/notification/xp_sound.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: GestureDetector(
            onTap: () =>
                _controller.reverse().then((_) => widget.onDismiss()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.stars_rounded,
                        color: Color(0xFFFF6B35), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+${widget.xp} XP',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF6B35),
                              fontSize: 16,
                              decoration: TextDecoration.none)),
                      Text(widget.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                              decoration: TextDecoration.none)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        _controller.reverse().then((_) => widget.onDismiss()),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.5), size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}