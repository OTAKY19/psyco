import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/app_export.dart';

class StudyCalendarWidget extends StatefulWidget {
  final Map<DateTime, int> studyData;
  final Function(DateTime) onDaySelected;

  const StudyCalendarWidget({
    Key? key,
    required this.studyData,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<StudyCalendarWidget> createState() => _StudyCalendarWidgetState();
}

class _StudyCalendarWidgetState extends State<StudyCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  Color _getActivityColor(int testsCompleted) {
    if (testsCompleted == 0) return Colors.transparent;
    if (testsCompleted <= 2)
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3);
    if (testsCompleted <= 4)
      return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.6);
    return AppTheme.lightTheme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendrier d\'étude',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              CustomIconWidget(
                iconName: 'calendar_view_month',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
            ],
          ),
          SizedBox(height: 3.h),
          TableCalendar<int>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return widget.studyData[normalizedDay] != null
                  ? [widget.studyData[normalizedDay]!]
                  : [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle:
                  AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ) ?? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
              holidayTextStyle:
                  AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ) ?? TextStyle(color: AppTheme.lightTheme.colorScheme.error),
              defaultTextStyle:
                  AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ) ?? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface),
              selectedDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ) ?? TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              leftChevronIcon: CustomIconWidget(
                iconName: 'chevron_left',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              rightChevronIcon: CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ) ?? TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ) ?? TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final testsCompleted = widget.studyData[normalizedDay] ?? 0;

                return Container(
                  margin: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: _getActivityColor(testsCompleted),
                    shape: BoxShape.circle,
                    border: testsCompleted > 0
                        ? Border.all(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: testsCompleted > 2
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: testsCompleted > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDaySelected(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Aucun test', Colors.transparent),
              _buildLegendItem(
                  '1-2 tests',
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3)),
              _buildLegendItem(
                  '3-4 tests',
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.6)),
              _buildLegendItem(
                  '5+ tests', AppTheme.lightTheme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: color == Colors.transparent
                ? Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  )
                : null,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}