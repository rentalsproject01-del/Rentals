import 'package:flutter/material.dart';

class ProductRequestBar extends StatefulWidget {
  const ProductRequestBar({super.key, required this.onSendRequest});

  final Future<void> Function() onSendRequest;

  @override
  State<ProductRequestBar> createState() => _ProductRequestBarState();
}

class _ProductRequestBarState extends State<ProductRequestBar> {
  bool _isRequesting = false;

  Future<void> _handleSendRequest() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);
    try {
      await widget.onSendRequest();
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF113F67), Color(0xFF217DCD)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _handleSendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Send Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
