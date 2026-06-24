import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/biller.dart';
import '../../bloc/transfer_bloc.dart';
import '../../bloc/transfer_event.dart';
import '../../bloc/transfer_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import 'pay_bill_details_screen.dart';

class BillPaymentsScreen extends StatefulWidget {
  const BillPaymentsScreen({super.key});

  @override
  State<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends State<BillPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(FetchBillers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pay Bills', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
        centerTitle: true,
      ),
      body: BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) {
          if (state is TransferLoading) {
            return const AppLoadingView(message: 'Loading billers...');
          } else if (state is BillersLoaded) {
            // Group by category
            final Map<String, List<BillerEntity>> grouped = {};
            for (var b in state.billers) {
              grouped.putIfAbsent(b.category, () => []).add(b);
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries.map((entry) {
                  return _buildCategorySection(context, entry.key, entry.value);
                }).toList(),
              ),
            );
          } else if (state is TransferError) {
            return AppErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, String title, List<BillerEntity> billers) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: theme.textTheme.titleLarge?.color
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Column(
            children: List.generate(billers.length, (index) {
              final biller = billers[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconData(biller.icon), color: theme.primaryColor, size: 24),
                    ),
                    title: Text(biller.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(biller.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PayBillDetailsScreen(biller: biller)),
                      );
                    },
                  ),
                  if (index != billers.length - 1) 
                    Divider(height: 1, indent: 72, color: theme.dividerColor.withOpacity(0.05)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'bolt': return Icons.bolt;
      case 'water_drop': return Icons.water_drop;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'wifi': return Icons.wifi;
      case 'tv': return Icons.tv;
      case 'smartphone': return Icons.smartphone;
      case 'sim_card': return Icons.sim_card;
      default: return Icons.payment;
    }
  }
}
