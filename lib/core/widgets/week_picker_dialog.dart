import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/sri_lankan_holidays.dart';

class WeekPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const WeekPickerDialog({
    super.key,
    required this.initialDate,
  });

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedWeekStart;
  String? _hoveredHolidayName;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedWeekStart = _getWeekStart(widget.initialDate);
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  bool _isInSelectedWeek(DateTime date) {
    final weekEnd = _getWeekEnd(_selectedWeekStart);
    return date.isAtSameMomentAs(_selectedWeekStart) ||
        date.isAtSameMomentAs(weekEnd) ||
        (date.isAfter(_selectedWeekStart) && date.isBefore(weekEnd));
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMonthNavigation(),
            const SizedBox(height: 16),
            _buildWeekDayHeaders(),
            const SizedBox(height: 8),
            _buildCalendar(),
            const SizedBox(height: 12),
            if (_hoveredHolidayName != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _hoveredHolidayName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Select Week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${DateFormat('MMM dd').format(_selectedWeekStart)} - ${DateFormat('MMM dd, yyyy').format(_getWeekEnd(_selectedWeekStart))}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekDayHeaders() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        Color color = Colors.grey[700]!;
        
        // Color weekends differently
        if (day == 'Sat') {
          color = Colors.blue[700]!;
        } else if (day == 'Sun') {
          color = Colors.orange[700]!;
        }
        
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = _currentMonth;
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Start from Monday of the week containing first day
    final start = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );
    
    // End at Sunday of the week containing last day
    final end = lastDayOfMonth.add(
      Duration(days: 7 - lastDayOfMonth.weekday),
    );

    final weeks = <List<DateTime>>[];
    DateTime current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(current);
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Column(
      children: weeks.map((week) => _buildWeekRow(week)).toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: week.map((date) => _buildDayCell(date)).toList(),
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isToday = DateTime(date.year, date.month, date.day).isAtSameMomentAs(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    final isSelected = _isInSelectedWeek(date);
    final isHoliday = SriLankanHolidays.isHoliday(date);
    final isSaturday = date.weekday == DateTime.saturday;
    final isSunday = date.weekday == DateTime.sunday;
    
    Color? backgroundColor;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;
    
    if (isSelected) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.2);
      fontWeight = FontWeight.bold;
    }
    
    if (isToday) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
    }
    
    if (isHoliday) {
      textColor = Colors.red[700]!;
      fontWeight = FontWeight.bold;
    }
    
    if (!isCurrentMonth) {
      textColor = Colors.grey[400]!;
    }
    
    // Weekend colors (if not holiday or selected)
    if (!isToday && !isHoliday) {
      if (isSaturday) {
        textColor = Colors.blue[700]!;
      } else if (isSunday) {
        textColor = Colors.orange[700]!;
      }
    }

    return Expanded(
      child: InkWell(
        onTap: isCurrentMonth
            ? () {
                setState(() {
                  _selectedWeekStart = _getWeekStart(date);
                  if (isHoliday) {
                    _hoveredHolidayName = SriLankanHolidays.getHolidayName(date);
                  } else {
                    _hoveredHolidayName = null;
                  }
                });
              }
            : null,
        onLongPress: isHoliday && isCurrentMonth
            ? () {
                final holidayName = SriLankanHolidays.getHolidayName(date);
                if (holidayName != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.celebration, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(holidayName)),
                        ],
                      ),
                      backgroundColor: Colors.red[700],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : isHoliday
                    ? Border.all(color: Colors.red[300]!, width: 1)
                    : null,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: fontWeight,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isHoliday && isCurrentMonth)
                  Positioned(
                    bottom: 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildLegendItem(Colors.blue[700]!, 'Saturday'),
              _buildLegendItem(Colors.orange[700]!, 'Sunday'),
              _buildLegendItem(Colors.red[700]!, 'Holiday'),
              _buildLegendItem(AppColors.primary, 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedWeekStart);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// Helper function to show the week picker
Future<DateTime?> showWeekPicker({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  return await showDialog<DateTime>(
    context: context,
    builder: (context) => WeekPickerDialog(initialDate: initialDate),
  );
}
