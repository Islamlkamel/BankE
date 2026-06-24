import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/notification/notification_bloc.dart';
import '../../bloc/notification/notification_event.dart';
import '../../bloc/notification/notification_state.dart';
import '../../../data/models/notification_model.dart';
import 'notification_details_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const FetchNotificationsEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationBloc>().add(const LoadMoreNotificationsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textTheme.titleLarge?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final hasUnread = state is NotificationLoaded &&
                  state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // state is already confirmed NotificationLoaded via hasUnread check above
                  for (final n in state.notifications) {
                    if (!n.isRead) {
                      context
                          .read<NotificationBloc>()
                          .add(MarkNotificationReadEvent(n.id));
                    }
                  }
                },
                icon: Icon(Icons.done_all_rounded,
                    size: 18, color: theme.primaryColor),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return _buildSkeleton(isDark);
          }

          if (state is NotificationError) {
            return _buildEmpty(
              icon: Icons.wifi_off_rounded,
              title: 'Failed to load',
              subtitle: state.message,
              isDark: isDark,
              showRetry: true,
              theme: theme,
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmpty(
                icon: Icons.notifications_none_rounded,
                title: 'All caught up!',
                subtitle: 'You have no notifications right now.',
                isDark: isDark,
                theme: theme,
              );
            }

            return RefreshIndicator(
              color: theme.primaryColor,
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const FetchNotificationsEvent(refresh: true));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.notifications.length +
                    (state is NotificationLoadingMore ? 1 : 0) +
                    (state.hasMore && state is! NotificationLoadingMore ? 0 : 0),
                itemBuilder: (context, index) {
                  if (index == state.notifications.length) {
                    // Loading more indicator
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    );
                  }
                  final notification = state.notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    isDark: isDark,
                    onTap: () => _onNotificationTap(notification),
                    onDismiss: () => _onDismiss(notification),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    HapticFeedback.lightImpact();
    // Mark as read for notifications with no referenceId
    if (notification.referenceId == null && !notification.isRead) {
      context
          .read<NotificationBloc>()
          .add(MarkNotificationReadEvent(notification.id));
    }
    // Always show the smart details sheet (it handles all types)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationBloc>(),
        child: NotificationDetailsSheet(notification: notification),
      ),
    );
  }

  void _onDismiss(NotificationModel notification) {
    context
        .read<NotificationBloc>()
        .add(DeleteNotificationEvent(notification.id));
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, i) => _SkeletonCard(isDark: isDark),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required ThemeData theme,
    bool showRetry = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                )),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (showRetry) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const FetchNotificationsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ─── Individual Notification Card ────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.cardColor
                : theme.primaryColor.withOpacity(isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? theme.dividerColor.withOpacity(0.08)
                  : theme.primaryColor.withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(theme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                fontSize: 15,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (notification.referenceId != null) ...[
                            const Spacer(),
                            Text(
                              'View details →',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final info = _typeInfo(notification);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(info.$1, color: info.$2, size: 22),
    );
  }

  static (IconData, Color) _typeInfo(NotificationModel notification) {
    switch (notification.type?.toLowerCase()) {
      case 'atmdeposit':
        return (Icons.arrow_downward_rounded, Colors.green);
      case 'atmwithdrawal':
        return (Icons.arrow_upward_rounded, Colors.red);
      case 'transfer':
        if (notification.actorType?.toLowerCase() == 'sender') {
          return (Icons.send_rounded, Colors.orange);
        } else {
          return (Icons.call_received_rounded, Colors.teal);
        }
      case 'billpayment':
        return (Icons.receipt_long_rounded, Colors.purple);
      case 'loan':
        final title = notification.title.toLowerCase();
        if (title.contains('approved')) {
          return (Icons.check_circle_outline_rounded, Colors.green);
        } else if (title.contains('rejected')) {
          return (Icons.cancel_outlined, Colors.red);
        } else {
          return (Icons.account_balance_rounded, Colors.blue);
        }
      default:
        return (Icons.notifications_rounded, Colors.blueGrey);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d, y').format(dt);
  }
}

// ─── Skeleton Loader Card ─────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(_anim.value),
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(_anim.value),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(_anim.value * 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
