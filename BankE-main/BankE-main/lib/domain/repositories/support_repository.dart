import '../entities/message_entity.dart';

abstract class SupportRepository {
  Future<MessageEntity> sendMessage(String text);
}
