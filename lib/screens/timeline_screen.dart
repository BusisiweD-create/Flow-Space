import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_card.dart';
import '../theme/flownet_theme.dart';
import '../widgets/app_modal.dart';
import '../models/timeline_event.dart';
import '../services/auth_service.dart';
import 'add_event_modal.dart';

/// Timeline/Calendar Screen
/// Accessible by all users
/// Displays events, deadlines, and schedule in a calendar/timeline view
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // View state
  String _activeView = 'Month'; // 'Month' | 'Week' | 'Day' | 'Timeline'

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Events
  final List<TimelineEvent> _events = [];

  // Calendar view constants
  static const int _startHour = 6; // 6 AM
  static const int _endHour = 22; // 10 PM
  static const double _hourHeight = 80.0; // Height of each hour slot in pixels
  static const double _minuteHeight = _hourHeight / 60.0; // Height per minute
  static const Duration _defaultEventDuration =
      Duration(hours: 1); // Default 1 hour for events

  @override
  void initState() {
    super.initState();
    _loadSampleEvents();
  }

  void _loadSampleEvents() {
    final now = DateTime.now();
    setState(() {
      _events.addAll([
        TimelineEvent(
          id: '1',
          title: 'Stand-Up Meeting',
          description: 'Daily stand-up with team',
          type: TimelineEventType.meeting,
          date: now,
          createdAt: now.subtract(const Duration(minutes: 10)),
          time: '08:30',
          priority: 'medium',
          project: 'Sprint Planning',
          colorTag: 'blue',
        ),
        TimelineEvent(
          id: '2',
          title: 'Working Group Session',
          description: 'Team collaboration session',
          type: TimelineEventType.task,
          date: now,
          createdAt: now.subtract(const Duration(minutes: 5)),
          time: '11:00',
          priority: 'high',
          project: 'Feature Development',
          colorTag: 'red',
        ),
        TimelineEvent(
          id: '3',
          title: 'Sprint Review',
          description: 'Review sprint progress',
          type: TimelineEventType.review,
          date: now.add(const Duration(days: 2)),
          createdAt: now,
          time: '14:00',
          priority: 'high',
          project: 'Sprint Planning',
          colorTag: 'green',
        ),
        TimelineEvent(
          id: '4',
          title: 'Training Session',
          description: 'Team training on new tools',
          type: TimelineEventType.other,
          date: now.add(const Duration(days: 5)),
          createdAt: now.add(const Duration(days: 1)),
          time: '10:00',
          priority: 'low',
          project: 'Training',
          colorTag: 'orange',
        ),
      ]);
    });
  }

  List<TimelineEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      final date = event.date;
      if (date == null) return false;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  List<TimelineEvent> _getEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return _events.where((event) {
      final date = event.date;
      if (date == null) return false;
      return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  void _addEvent(TimelineEvent event) {
    setState(() {
      _events.add(event);
    });
  }

  DateTime _getEventStartDateTime(TimelineEvent event) {
    return event.dateTime;
  }

  DateTime _getEventEndDateTime(TimelineEvent event) {
    // Default to 1 hour duration for events without duration
    return event.dateTime.add(_defaultEventDuration);
  }

  double _getEventTopPosition(DateTime eventTime) {
    final hours = eventTime.hour + (eventTime.minute / 60.0);
    final startHours = _startHour.toDouble();
    return (hours - startHours) * _hourHeight;
  }

  double _getEventHeight(DateTime startTime, DateTime endTime) {
    final duration = endTime.difference(startTime);
    return duration.inMinutes * _minuteHeight;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final userName = currentUser?.name.split(' ').first ?? 'User';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FlownetColors.charcoalBlack,
            FlownetColors.charcoalBlack.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                  maxWidth: 1400, // Desktop-first max width
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    _buildWelcomeBanner(userName),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // View Switcher
                    _buildViewSwitcher(),
                    const SizedBox(height: 24),

                    // Calendar/Timeline Content
                    _buildCalendarContent(),
                    const SizedBox(height: 24),

                    // My Deliverables
                    _buildMyDeliverables(),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildWelcomeBanner(String userName) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FlownetColors.crimsonRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.code,
              color: FlownetColors.crimsonRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FlownetColors.pureWhite,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Timeline & Calendar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FlownetColors.coolGray,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: FlownetColors.pureWhite,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add_task,
                title: 'Create Deliverable',
                onTap: () {
                  context.go('/deliverable-setup');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.timeline,
                title: 'Open Sprint Console',
                onTap: () {
                  context.go('/sprint-console');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.assessment,
                title: 'Build Report',
                onTap: () {
                  context.go('/report-repository');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      borderRadius: 16.0,
      opacity: 0.15,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: FlownetColors.crimsonRed),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: FlownetColors.pureWhite,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewButton('Month', Icons.calendar_view_month),
          const SizedBox(width: 8),
          _buildViewButton('Week', Icons.calendar_view_week),
          const SizedBox(width: 8),
          _buildViewButton('Day', Icons.calendar_today),
          const SizedBox(width: 8),
          _buildViewButton('Timeline', Icons.timeline),
        ],
      ),
    );
  }

  Widget _buildViewButton(String view, IconData icon) {
    final isActive = _activeView == view;
    return GlassContainer(
      onTap: () {
        setState(() {
          _activeView = view;
          if (view == 'Month') {
            _calendarFormat = CalendarFormat.month;
          } else if (view == 'Week') {
            _calendarFormat = CalendarFormat.week;
          }
        });
      },
      borderRadius: 12.0,
      opacity: isActive ? 0.20 : 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? FlownetColors.crimsonRed : FlownetColors.coolGray,
          ),
          const SizedBox(width: 8),
          Text(
            view,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? FlownetColors.crimsonRed
                      : FlownetColors.coolGray,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    switch (_activeView) {
      case 'Week':
        return _buildWeekView();
      case 'Day':
        return _buildDayView();
      case 'Timeline':
        return _buildTimelineView();
      case 'Month':
      default:
        return _buildCalendarView();
    }
  }

  Widget _buildWeekView() {
    final weekStart = _getWeekStart(_focusedDay);
    final weekDays =
        List.generate(7, (index) => weekStart.add(Duration(days: index)));
    final weekEvents = _getEventsForWeek(weekStart);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Week Header with Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: FlownetColors.slate.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: FlownetColors.pureWhite),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          _focusedDay.subtract(const Duration(days: 7));
                    });
                  },
                ),
                Text(
                  '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FlownetColors.pureWhite,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: FlownetColors.pureWhite),
                  onPressed: () {
                    setState(() {
                      _focusedDay = _focusedDay.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
          ),
          // Week Grid
          SizedBox(
            height: (_endHour - _startHour) * _hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: FlownetColors.slate.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Column(
                    children: List.generate(
                      _endHour - _startHour,
                      (index) => Container(
                        height: _hourHeight,
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        alignment: Alignment.topRight,
                        child: Text(
                          '${_startHour + index}:00',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: FlownetColors.coolGray,
                                    fontSize: 12,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Days Columns
                Expanded(
                  child: Row(
                    children: weekDays.map((day) {
                      final dayEvents = weekEvents.where((event) {
                        final date = event.date;
                        if (date == null) return false;
                        return date.year == day.year &&
                            date.month == day.month &&
                            date.day == day.day;
                      }).toList();

                      final isToday = day.year == DateTime.now().year &&
                          day.month == DateTime.now().month &&
                          day.day == DateTime.now().day;

                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: FlownetColors.slate
                                      .withValues(alpha: 0.3)),
                              bottom: BorderSide(
                                  color: FlownetColors.slate
                                      .withValues(alpha: 0.3)),
                            ),
                            color: isToday
                                ? FlownetColors.crimsonRed
                                    .withValues(alpha: 0.1)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // Hour Lines
                              Column(
                                children: List.generate(
                                  _endHour - _startHour,
                                  (index) => Container(
                                    height: _hourHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: FlownetColors.slate
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Day Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: FlownetColors.graphiteGray
                                      .withValues(alpha: 0.3),
                                  border: Border(
                                    bottom: BorderSide(
                                        color: FlownetColors.slate
                                            .withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(day),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: FlownetColors.coolGray,
                                            fontSize: 12,
                                          ),
                                    ),
                                    Text(
                                      '${day.day}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? FlownetColors.crimsonRed
                                                : FlownetColors.pureWhite,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Events
                              Positioned.fill(
                                top: 56,
                                child: Stack(
                                  children: dayEvents.map((event) {
                                    final startTime =
                                        _getEventStartDateTime(event);
                                    final endTime = _getEventEndDateTime(event);
                                    final top = _getEventTopPosition(startTime);
                                    final height =
                                        _getEventHeight(startTime, endTime);
                                    final color =
                                        _getColorForTag(event.colorTag);

                                    return Positioned(
                                      top: top,
                                      left: 4,
                                      right: 4,
                                      height:
                                          height.clamp(36.0, double.infinity),
                                      child: _buildWeekEventCard(event, color),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekEventCard(TimelineEvent event, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FlownetColors.pureWhite,
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                event.time ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayView() {
    final dayEvents = _getEventsForDay(_selectedDay);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Day Header with Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: FlownetColors.slate.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: FlownetColors.pureWhite),
                  onPressed: () {
                    setState(() {
                      _selectedDay =
                          _selectedDay.subtract(const Duration(days: 1));
                      _focusedDay = _selectedDay;
                    });
                  },
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: FlownetColors.pureWhite,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dayEvents.length} ${dayEvents.length == 1 ? 'event' : 'events'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: FlownetColors.coolGray,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: FlownetColors.pureWhite),
                  onPressed: () {
                    setState(() {
                      _selectedDay = _selectedDay.add(const Duration(days: 1));
                      _focusedDay = _selectedDay;
                    });
                  },
                ),
              ],
            ),
          ),
          // Day Timeline
          SizedBox(
            height: (_endHour - _startHour) * _hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: FlownetColors.slate.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Column(
                    children: List.generate(
                      _endHour - _startHour,
                      (index) => Container(
                        height: _hourHeight,
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        alignment: Alignment.topRight,
                        child: Text(
                          '${_startHour + index}:00',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: FlownetColors.coolGray,
                                    fontSize: 12,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Events Column
                Expanded(
                  child: Stack(
                    children: [
                      // Hour Lines
                      Column(
                        children: List.generate(
                          _endHour - _startHour,
                          (index) => Container(
                            height: _hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: FlownetColors.slate
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Events
                      Stack(
                        children: dayEvents.map((event) {
                          final startTime = _getEventStartDateTime(event);
                          final endTime = _getEventEndDateTime(event);
                          final top = _getEventTopPosition(startTime);
                          final height = _getEventHeight(startTime, endTime);
                          final color = _getColorForTag(event.colorTag);

                          return Positioned(
                            top: top,
                            left: 8,
                            right: 8,
                            height: height.clamp(48.0, double.infinity),
                            child: _buildDayEventCard(event, color),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEventCard(TimelineEvent event, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FlownetColors.pureWhite,
                      fontSize: 12,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                event.time ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: FlownetColors.pureWhite),
                onPressed: () {
                  setState(() {
                    if (_calendarFormat == CalendarFormat.month) {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1);
                    } else {
                      _focusedDay =
                          _focusedDay.subtract(const Duration(days: 7));
                    }
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FlownetColors.pureWhite,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: FlownetColors.pureWhite),
                onPressed: () {
                  setState(() {
                    if (_calendarFormat == CalendarFormat.month) {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1);
                    } else {
                      _focusedDay = _focusedDay.add(const Duration(days: 7));
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Calendar
          TableCalendar<TimelineEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return day.year == _selectedDay.year &&
                  day.month == _selectedDay.month &&
                  day.day == _selectedDay.day;
            },
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: FlownetColors.coolGray),
              defaultTextStyle: const TextStyle(color: FlownetColors.pureWhite),
              selectedTextStyle: const TextStyle(
                color: FlownetColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: const TextStyle(
                color: FlownetColors.crimsonRed,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: BoxDecoration(
                color: FlownetColors.crimsonRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: FlownetColors.crimsonRed,
                  width: 2,
                ),
              ),
              selectedDecoration: BoxDecoration(
                color: FlownetColors.crimsonRed.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: FlownetColors.crimsonRed,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: FlownetColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: FlownetColors.pureWhite,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: FlownetColors.pureWhite,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: FlownetColors.coolGray),
              weekendStyle: TextStyle(color: FlownetColors.coolGray),
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: _onFormatChanged,
            onPageChanged: _onPageChanged,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: FlownetColors.crimsonRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Selected Day Events
          if (_getEventsForDay(_selectedDay).isNotEmpty) ...[
            const Divider(color: FlownetColors.slate),
            const SizedBox(height: 16),
            Text(
              'Events on ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FlownetColors.pureWhite,
                  ),
            ),
            const SizedBox(height: 12),
            ..._getEventsForDay(_selectedDay)
                .map((event) => _buildEventChip(event)),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    final sortedEvents = List<TimelineEvent>.from(_events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: FlownetColors.pureWhite,
                ),
          ),
          const SizedBox(height: 16),
          if (sortedEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_busy,
                      size: 48,
                      color: FlownetColors.coolGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No events scheduled',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: FlownetColors.coolGray,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sortedEvents.map((event) => _buildTimelineItem(event)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event) {
    final color = _getColorForTag(event.colorTag);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(event),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy')
                              .format(event.date ?? DateTime.now()),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: FlownetColors.coolGray,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (event.priority ?? '').toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: FlownetColors.pureWhite,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.time ?? ''} • ${event.project ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: FlownetColors.coolGray,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventChip(TimelineEvent event) {
    final color = _getColorForTag(event.colorTag);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showEventDetails(event),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: FlownetColors.pureWhite,
                          ),
                    ),
                    Text(
                      '${event.time ?? ''} • ${event.project ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: FlownetColors.coolGray,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(TimelineEvent event) {
    showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.graphiteGray,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: _getColorForTag(event.colorTag),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                  color: FlownetColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: FlownetColors.coolGray),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: FlownetColors.coolGray,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(color: FlownetColors.pureWhite),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close',
                style: TextStyle(color: FlownetColors.crimsonRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDeliverables() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description,
                    color: FlownetColors.crimsonRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Deliverables',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: FlownetColors.pureWhite,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.go('/repository');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(color: FlownetColors.crimsonRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDeliverableItem(
            title: 'Sprint Run',
            status: 'approved',
            daysRemaining: 36,
            priority: 'medium',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverableItem({
    required String title,
    required String status,
    required int daysRemaining,
    required String priority,
  }) {
    final isApproved = status == 'approved';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/repository'),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isApproved)
                    const Icon(Icons.check_circle,
                        color: FlownetColors.emeraldGreen, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$title • $status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: FlownetColors.pureWhite,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FlownetColors.amberOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 14, color: FlownetColors.amberOrange),
                        const SizedBox(width: 4),
                        Text(
                          priority,
                          style: const TextStyle(
                            color: FlownetColors.amberOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: FlownetColors.coolGray),
                  const SizedBox(width: 4),
                  Text(
                    'In $daysRemaining days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FlownetColors.coolGray,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showAppDialog(
          context: context,
          builder: (context) => AddEventModal(
            onEventAdded: _addEvent,
          ),
        );
      },
      backgroundColor: FlownetColors.crimsonRed,
      foregroundColor: FlownetColors.pureWhite,
      icon: const Icon(Icons.add),
      label: const Text('New Event'),
      elevation: 8,
    );
  }

  Color _getColorForTag(String? tag) {
    switch (tag) {
      case 'red':
        return FlownetColors.crimsonRed;
      case 'blue':
        return FlownetColors.electricBlue;
      case 'green':
        return FlownetColors.emeraldGreen;
      case 'orange':
        return FlownetColors.amberOrange;
      case 'purple':
        return FlownetColors.purple;
      default:
        return FlownetColors.crimsonRed;
    }
  }
}
