import 'package:flutter/material.dart';

Future<bool?> showAppConfirmationSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  final accentColor = isDestructive
      ? const Color(0xFFFF6B78)
      : const Color(0xFF16BCE6);

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _AppSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF113F67),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5F7182),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SheetActionButton(
                    label: cancelLabel,
                    onTap: () => Navigator.pop(sheetContext, false),
                    isFilled: false,
                    color: const Color(0xFF113F67),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetActionButton(
                    label: confirmLabel,
                    onTap: () => Navigator.pop(sheetContext, true),
                    isFilled: true,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<int?> showRentalDaysSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _RentalDaysSheet(
        initialDays: 3,
        onConfirm: (days) => Navigator.pop(sheetContext, days),
      );
    },
  );
}

class _AppSheetFrame extends StatelessWidget {
  const _AppSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF113F67).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E5EF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RentalDaysSheet extends StatefulWidget {
  const _RentalDaysSheet({required this.initialDays, required this.onConfirm});

  final int initialDays;
  final ValueChanged<int> onConfirm;

  @override
  State<_RentalDaysSheet> createState() => _RentalDaysSheetState();
}

class _RentalDaysSheetState extends State<_RentalDaysSheet> {
  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: _selectedDays));

    return _AppSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set Rental Duration',
            style: TextStyle(
              color: Color(0xFF113F67),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how many days you want to approve this rental for.',
            style: TextStyle(
              color: Color(0xFF5F7182),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(7, (index) {
              final days = index + 1;
              final isSelected = days == _selectedDays;
              return GestureDetector(
                onTap: () => setState(() => _selectedDays = days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF113F67)
                        : const Color(0xFFF3F8FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF16BCE6)
                          : const Color(0xFFD8E8F2),
                    ),
                  ),
                  child: Text(
                    '$days Day${days > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF113F67),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF113F67), Color(0xFF1B5F94)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DateMetaCard(
                    label: 'Starts',
                    value: _formatShortDate(startDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateMetaCard(
                    label: 'Ends',
                    value: _formatShortDate(endDate),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SheetActionButton(
            label: 'Confirm $_selectedDays Day${_selectedDays > 1 ? 's' : ''}',
            onTap: () => widget.onConfirm(_selectedDays),
            isFilled: true,
            color: const Color(0xFF16BCE6),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _DateMetaCard extends StatelessWidget {
  const _DateMetaCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.onTap,
    required this.isFilled,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool isFilled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: isFilled ? color : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isFilled ? Colors.white : color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
