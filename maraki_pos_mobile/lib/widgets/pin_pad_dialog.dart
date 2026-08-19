import 'package:flutter/material.dart';

class PinPadDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String pin) onConfirm;

  const PinPadDialog({
    super.key,
    this.title = 'የደህንነት PIN ማረጋገጫ (Security PIN)',
    this.subtitle = 'እባክዎ 4-ዲጂት የይለፍ ቃል ያስገቡ (ነባሪ PIN: 1234)',
    required this.onConfirm,
  });

  @override
  State<PinPadDialog> createState() => _PinPadDialogState();
}

class _PinPadDialogState extends State<PinPadDialog> {
  String _pin = '';
  String? _errorMessage;

  void _handleNumberPress(String num) {
    if (_pin.length < 4) {
      setState(() {
        _pin += num;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _handleBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    if (_pin == '1234') {
      Navigator.of(context).pop();
      widget.onConfirm(_pin);
    } else {
      setState(() {
        _errorMessage = 'የተሳሳተ PIN! እባክዎ እንደገና ይሞክሩ (ነባሪ: 1234)';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFC05621), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A202C)),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // 4-PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? const Color(0xFFE53E3E) : Colors.grey.shade200,
                    border: Border.all(
                      color: isFilled ? const Color(0xFFE53E3E) : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 24),

            // Numeric Keypad 1-9, 0, Backspace
            Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('ሰርዝ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    _buildKeypadButton('0'),
                    IconButton(
                      onPressed: _handleBackspace,
                      icon: const Icon(Icons.backspace_outlined, color: Colors.grey),
                      iconSize: 28,
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildKeypadButton(n)).toList(),
    );
  }

  Widget _buildKeypadButton(String number) {
    return InkWell(
      onTap: () => _handleNumberPress(number),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3748)),
        ),
      ),
    );
  }
}
