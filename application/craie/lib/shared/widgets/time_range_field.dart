import 'package:flutter/material.dart';

/// "08:00 à 13:00" boxes. Not tappable when [onPickStart]/[onPickEnd] are null.
/// With an [errorText] both boxes get a red outline and the message is shown below.
class TimeRangeField extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;
  final VoidCallback? onPickStart;
  final VoidCallback? onPickEnd;
  final String? errorText;

  const TimeRangeField({
    super.key,
    required this.start,
    required this.end,
    this.onPickStart,
    this.onPickEnd,
    this.errorText,
  });

  static const _red = Color(0xFFE53935);

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _box(TimeOfDay t, VoidCallback? onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDED9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: errorText != null ? _red : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(_fmt(t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _box(start, onPickStart),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('à', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            _box(end, onPickEnd),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(errorText!,
                style: const TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
