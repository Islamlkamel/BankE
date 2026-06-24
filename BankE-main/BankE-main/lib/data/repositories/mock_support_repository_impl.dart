import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/support_repository.dart';

class MockSupportRepositoryImpl implements SupportRepository {
  final _uuid = const Uuid();

  @override
  Future<MessageEntity> sendMessage(String text) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Mock typing delay
    
    String botReply = "I am the automated assistant. How can I help you today?";
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains("balance")) {
      botReply = "You can view your available balance on the main Dashboard.";
    } else if (lowerText.contains("transfer") || lowerText.contains("send")) {
      botReply = "To transfer money, tap on 'Transfer' in the Dashboard and enter the recipient's details.";
    } else if (lowerText.contains("card")) {
      botReply = "Manage your cards in the 'Cards' menu from the navigation bar. You can freeze or delete them there.";
    } else if (lowerText.contains("hello") || lowerText.contains("hi")) {
      botReply = "Hello! Welcome to Contro Bank Support. How can I assist you?";
    } else if (lowerText.contains("fraud") || lowerText.contains("stolen")) {
      botReply = "If you suspect fraud, please immediately navigate to Cards and use the 'Freeze Card' option. Then contact our urgent line.";
    }

    return MessageEntity(
      id: _uuid.v4(),
      text: botReply,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
