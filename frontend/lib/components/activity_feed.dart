import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';
import '../utils/date_utils.dart' as custom_date_utils;

class ActivityFeed extends ConsumerStatefulWidget {
  final int? maxItems;
  final bool showTimestamps;
  final bool showClearButton;

  const ActivityFeed({
    super.key,
    this.maxItems,
    this.showTimestamps = true,
    this.showClearButton = false,
  });

  @override
  ConsumerState<ActivityFeed> createState() => _ActivityFeedState();
}

class _ActivityFeedState extends ConsumerState<ActivityFeed> {
  final List<ActivityEvent> _activities = [];
  final ScrollController _scrollController = ScrollController();
  late final RealtimeService realtimeService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeListeners();
    });
  }

  void _setupRealtimeListeners() {
    realtimeService = ref.read(realtimeService as ProviderListenable<RealtimeService>);
    
    // Listen for deliverable events
    realtimeService.on('deliverable_created', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.deliverable,
        message: 'New deliverable created: ${data['title']}',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    realtimeService.on('deliverable_updated', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.deliverable,
        message: 'Deliverable updated: ${data['title']}',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    // Listen for sprint events
    realtimeService.on('sprint_created', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.sprint,
        message: 'New sprint started: ${data['name']}',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    realtimeService.on('sprint_updated', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.sprint,
        message: 'Sprint updated: ${data['name']}',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    // Listen for user presence events
    realtimeService.on('user_online', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.user,
        message: '${data['userName']} came online',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    realtimeService.on('user_offline', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.user,
        message: '${data['userName']} went offline',
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });

    // Listen for general activity events
    realtimeService.on('activity_created', (data) {
      _addActivity(ActivityEvent(
        type: ActivityType.general,
        message: data['message'],
        timestamp: DateTime.now(),
        userId: data['userId'],
        data: data,
      ),);
    });
  }

  void _addActivity(ActivityEvent activity) {
    setState(() {
      _activities.insert(0, activity);
      if (widget.maxItems != null && _activities.length > widget.maxItems!) {
        _activities.removeLast();
      }
    });

    // Auto-scroll to top for new activities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearActivities() {
    setState(() {
      _activities.clear();
    });
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.deliverable:
        return Colors.blue;
      case ActivityType.sprint:
        return Colors.green;
      case ActivityType.user:
        return Colors.orange;
      case ActivityType.general:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.deliverable:
        return Icons.assignment;
      case ActivityType.sprint:
        return Icons.directions_run;
      case ActivityType.user:
        return Icons.person;
      case ActivityType.general:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showClearButton && _activities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearActivities,
                child: const Text('Clear All'),
              ),
            ),
          ),
        
        Expanded(
          child: _activities.isEmpty
              ? const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    return _buildActivityItem(activity);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(ActivityEvent activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.type),
          child: Icon(
            _getActivityIcon(activity.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          activity.message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: widget.showTimestamps
            ? Text(
                custom_date_utils.DateUtils.formatRelativeTime(activity.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class ActivityEvent {
  final ActivityType type;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? data;

  ActivityEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.userId,
    this.data,
  });
}

enum ActivityType {
  deliverable,
  sprint,
  user,
  general,
}