import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/account_data_source.dart';
import '../../../data/models/notification_model.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final AccountDataSource dataSource;
  static const int _pageSize = 20;

  NotificationBloc({required this.dataSource}) : super(NotificationInitial()) {
    on<FetchNotificationsEvent>(_onFetch);
    on<LoadMoreNotificationsEvent>(_onLoadMore);
    on<FetchUnreadCountEvent>(_onFetchUnreadCount);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<DeleteNotificationEvent>(_onDelete);
  }

  Future<void> _onFetch(
      FetchNotificationsEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final results = await Future.wait([
        dataSource.fetchNotificationsPaged(page: 1, pageSize: _pageSize),
        dataSource.fetchUnreadCount(),
      ]);

      final paged = results[0] as Map<String, dynamic>;
      final unreadCount = results[1] as int;

      final items = (paged['items'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final hasMore = paged['hasMore'] as bool? ?? false;

      emit(NotificationLoaded(
        notifications: items,
        unreadCount: unreadCount,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreNotificationsEvent event, Emitter<NotificationState> emit) async {
    final current = state;
    if (current is! NotificationLoaded || !current.hasMore) return;

    emit(NotificationLoadingMore(
      notifications: current.notifications,
      unreadCount: current.unreadCount,
      hasMore: current.hasMore,
      currentPage: current.currentPage,
    ));

    try {
      final nextPage = current.currentPage + 1;
      final paged = await dataSource.fetchNotificationsPaged(
          page: nextPage, pageSize: _pageSize);

      final newItems = (paged['items'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final hasMore = paged['hasMore'] as bool? ?? false;

      emit(current.copyWith(
        notifications: [...current.notifications, ...newItems],
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onFetchUnreadCount(
      FetchUnreadCountEvent event, Emitter<NotificationState> emit) async {
    try {
      final count = await dataSource.fetchUnreadCount();
      // If we have a loaded state, update it in place
      final current = state;
      if (current is NotificationLoaded) {
        emit(current.copyWith(unreadCount: count));
      } else {
        emit(UnreadCountLoaded(count));
      }
    } catch (_) {
      // Silently ignore count errors
    }
  }

  Future<void> _onMarkRead(
      MarkNotificationReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await dataSource.markNotificationAsRead(event.id);
      final current = state;
      if (current is NotificationLoaded) {
        final updated = current.notifications.map((n) {
          return n.id == event.id ? n.copyWith(isRead: true) : n;
        }).toList();
        final newUnread =
            (current.unreadCount - 1).clamp(0, current.unreadCount);
        emit(current.copyWith(
            notifications: updated, unreadCount: newUnread));
      }
    } catch (_) {
      // Silently ignore mark-as-read errors
    }
  }

  Future<void> _onDelete(
      DeleteNotificationEvent event, Emitter<NotificationState> emit) async {
    try {
      await dataSource.deleteNotification(event.id);
      final current = state;
      if (current is NotificationLoaded) {
        final wasUnread =
            current.notifications.any((n) => n.id == event.id && !n.isRead);
        final updated =
            current.notifications.where((n) => n.id != event.id).toList();
        final newUnread = wasUnread
            ? (current.unreadCount - 1).clamp(0, current.unreadCount)
            : current.unreadCount;
        emit(current.copyWith(
            notifications: updated, unreadCount: newUnread));
      }
    } catch (_) {
      // Silently ignore delete errors
    }
  }

}
