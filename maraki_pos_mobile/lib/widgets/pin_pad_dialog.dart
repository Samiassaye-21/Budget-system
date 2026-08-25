import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PinPadDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String> onConfirm;
  final String requiredPin;

  const PinPadDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    this.requiredPin = '9999',
  });

  @override
  State<PinPadDialog> createState() => _PinPadDialogState();
}

class _PinPadDialogState extends State<PinPadDialog> {
  String _pin = '';
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleNumberPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _validatePin();
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

  void _validatePin() {
    if (_pin == widget.requiredPin || widget.requiredPin.isEmpty) {
      Navigator.of(context).pop();
      widget.onConfirm(_pin);
    } else {
      setState(() {
        _errorMessage = 'የተሳሳተ PIN ነው! እባክዎ እንደገና ይሞክሩ።';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.backspace) {
            _handleBackspace();
          } else if (key == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          } else {
            final char = event.character;
            if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
              _handleNumberPress(char);
            }
          }
        }
      },
      child: Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.obsidian),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    color: isFilled ? AppColors.primary : AppColors.border,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.slate,
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
