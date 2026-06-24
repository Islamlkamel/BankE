import '../repositories/support_repository.dart';
import '../entities/message_entity.dart';

class SendMessageUseCase {
  final SupportRepository repository;

  SendMessageUseCase(this.repository);

  Future<MessageEntity> execute(String text) async {
    return await repository.sendMessage(text);
  }
}
