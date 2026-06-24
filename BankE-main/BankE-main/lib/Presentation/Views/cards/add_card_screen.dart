import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/card_entity.dart';
import '../../bloc/card/card_bloc.dart';
import '../../bloc/card/card_event.dart';
import '../../bloc/card/card_state.dart';
import '../../../core/constants/app_constants.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isVirtual = false;
  String _cardType = 'Debit';

  @override
  void dispose() {
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final uuid = const Uuid().v4();
      final newCard = CardEntity(
        id: uuid,
        cardNumber: '',
        cardHolderName: '',
        expiryDate: '',
        cvv: '',
        isFrozen: false,
        isVirtual: _isVirtual,
        cardType: _cardType,
      );

      context.read<CardBloc>().add(AddCardEvent(AppConstants.currentAccountId, newCard));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Card'),
      ),
      body: BlocListener<CardBloc, CardState>(
        listener: (context, state) {
          if (state is CardOperationSuccess) {
            Navigator.pop(context); // Go back after success
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: _cardType,
                  decoration: const InputDecoration(
                    labelText: 'Card Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Debit', 'Credit']
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _cardType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Virtual Card'),
                  subtitle: const Text('Enable if this is a virtual card (no physical copy)'),
                  value: _isVirtual,
                  onChanged: (value) {
                    setState(() {
                      _isVirtual = value;
                    });
                  },
                ),
                const SizedBox(height: 32),
                BlocBuilder<CardBloc, CardState>(
                  builder: (context, state) {
                    if (state is CardLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Add Card', style: TextStyle(fontSize: 16)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
