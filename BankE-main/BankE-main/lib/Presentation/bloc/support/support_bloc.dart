import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/usecases/send_message.dart';

// Events
abstract class SupportEvent extends Equatable {
  const SupportEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends SupportEvent {
  final String text;
  const SendMessageEvent(this.text);
  @override
  List<Object?> get props => [text];
}

// State
class SupportState extends Equatable {
  final List<MessageEntity> messages;
  final bool isBotTyping;

  const SupportState({
    this.messages = const [],
    this.isBotTyping = false,
  });

  SupportState copyWith({
    List<MessageEntity>? messages,
    bool? isBotTyping,
  }) {
    return SupportState(
      messages: messages ?? this.messages,
      isBotTyping: isBotTyping ?? this.isBotTyping,
    );
  }

  @override
  List<Object?> get props => [messages, isBotTyping];
}

// BLoC
class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SendMessageUseCase sendMessageUseCase;
  final _uuid = const Uuid();

  SupportBloc({required this.sendMessageUseCase}) : super(const SupportState()) {
    on<SendMessageEvent>(_onSendMessage);

    // Initial greeting!
    emit(state.copyWith(
      messages: [
        MessageEntity(
          id: _uuid.v4(),
          text: "Hi there! I'm your Contro virtual assistant. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        )
      ]
    ));
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<SupportState> emit) async {
    final userMessage = MessageEntity(
      id: _uuid.v4(),
      text: event.text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: List.from(state.messages)..add(userMessage),
      isBotTyping: true,
    ));

    try {
      final botMessage = await sendMessageUseCase.execute(event.text);
      emit(state.copyWith(
        messages: List.from(state.messages)..add(botMessage),
        isBotTyping: false,
      ));
    } catch (_) {
      // In case of error (never happens in mock, but good practice)
       emit(state.copyWith(
        messages: List.from(state.messages)..add(
          MessageEntity(
            id: _uuid.v4(),
            text: "Sorry, I am having trouble connecting to the network.",
            isUser: false,
            timestamp: DateTime.now(),
          )
        ),
        isBotTyping: false,
      ));
    }
  }
}
