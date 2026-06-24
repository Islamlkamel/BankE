import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class FetchNotificationsEvent extends NotificationEvent {
  final int page;
  final int pageSize;
  final bool refresh;

  const FetchNotificationsEvent({
    this.page = 1,
    this.pageSize = 20,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, pageSize, refresh];
}

class LoadMoreNotificationsEvent extends NotificationEvent {
  const LoadMoreNotificationsEvent();
}

class FetchUnreadCountEvent extends NotificationEvent {
  const FetchUnreadCountEvent();
}

class MarkNotificationReadEvent extends NotificationEvent {
  final int id;
  const MarkNotificationReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteNotificationEvent extends NotificationEvent {
  final int id;
  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchTransactionDetailsEvent extends NotificationEvent {
  final int transactionId;
  const FetchTransactionDetailsEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
