import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.hasMore = false,
    this.currentPage = 1,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, hasMore, currentPage];
}

class NotificationLoadingMore extends NotificationLoaded {
  const NotificationLoadingMore({
    required super.notifications,
    required super.unreadCount,
    super.hasMore,
    super.currentPage,
  });
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// States for transaction detail fetch (used in UI directly)
class TransactionDetailLoading extends NotificationState {}

class TransactionDetailLoaded extends NotificationState {
  final Map<String, dynamic> transaction;
  const TransactionDetailLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionDetailError extends NotificationState {
  final String message;
  const TransactionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class UnreadCountLoaded extends NotificationState {
  final int count;
  const UnreadCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}
