import 'package:equatable/equatable.dart';

class BillerEntity extends Equatable {
  final String id;
  final String name;
  final String category; // e.g., 'Electricity', 'Water', 'Internet'
  final String icon;    // Not used yet, but good for future icons

  const BillerEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });

  @override
  List<Object?> get props => [id, name, category, icon];
}
