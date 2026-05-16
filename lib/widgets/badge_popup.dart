import 'package:flutter/material.dart';

class BadgePopup extends StatefulWidget {
  final String badgeName;
  final String badgeIcon;
  final String deskripsi;
  final VoidCallback onDismiss;

  const BadgePopup({
    super.key,
    required this.badgeName,
    required this.badgeIcon,
    required this.deskripsi,
    required this.onDismiss,
  });

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends State<BadgePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: GestureDetector(
              onTap: () {
                _controller.reverse().then((_) => widget.onDismiss());
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF7924A).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF7924A).withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7924A).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.badgeIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7924A).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🏅 Badge Baru!',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF7924A),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.badgeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            widget.deskripsi,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6),
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _controller
                          .reverse()
                          .then((_) => widget.onDismiss()),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.5),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}