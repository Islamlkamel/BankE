import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../bloc/transaction_bloc.dart';
import '../../bloc/transaction_state.dart';
import '../../widgets/analytics_helper.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Advanced Analytics', 
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: "Weekly Trends"),
            Tab(text: "Monthly Trends"),
          ],
        ),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const AppLoadingView();
          } else if (state is TransactionLoaded) {
            final transactions = state.transactions;
            final categoryTotals = AnalyticsHelper.getExpensesByCategory(transactions);
            final totalIncome = AnalyticsHelper.getTotalIncome(transactions);
            final totalExpenses = AnalyticsHelper.getTotalExpenses(transactions);

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTrendsView(context, categoryTotals, totalIncome, totalExpenses, AnalyticsHelper.getWeeklySpendingTrends(transactions), isWeekly: true),
                _buildTrendsView(context, categoryTotals, totalIncome, totalExpenses, AnalyticsHelper.getMonthlySpendingTrends(transactions, DateTime.now().year), isWeekly: false),
              ],
            );
          } else if (state is TransactionError) {
            return AppErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTrendsView(
    BuildContext context, 
    Map<SpendingCategory, double> categoryTotals, 
    double totalIncome, 
    double totalExpenses,
    Map<int, double> trendData,
    {required bool isWeekly}
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildSummaryCards(context, totalIncome, totalExpenses),
          const SizedBox(height: 32),
          Text(
            isWeekly ? 'Weekly Spending Chart' : 'Monthly Spending Chart', 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color
            )
          ),
          const SizedBox(height: 16),
          _buildLineChart(context, trendData, isWeekly: isWeekly),
          const SizedBox(height: 32),
          Text(
            'Categorized Breakdown', 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color
            )
          ),
          const SizedBox(height: 24),
          _buildPieChart(categoryTotals),
          const SizedBox(height: 32),
          _buildLegend(context, categoryTotals),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, double income, double expenses) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(context, 'Total Income', income, Colors.green, Icons.arrow_downward),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(context, 'Total Expenses', expenses, Colors.redAccent, Icons.arrow_upward),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, Map<int, double> data, {required bool isWeekly}) {
    List<FlSpot> spots = [];
    double maxY = 0;

    data.forEach((key, value) {
      if (value > maxY) maxY = value;
      spots.add(FlSpot(key.toDouble(), value));
    });

    if (maxY == 0) maxY = 100; // Default if no data

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: LineChart(
        LineChartData(
          minX: isWeekly ? 1 : 1,
          maxX: isWeekly ? 7 : 12,
          minY: 0,
          maxY: maxY * 1.2,
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4 == 0 ? 1 : maxY/4),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('\$${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
                }
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (isWeekly) {
                    switch (value.toInt()) {
                      case 1: text = 'Mon'; break;
                      case 2: text = 'Tue'; break;
                      case 3: text = 'Wed'; break;
                      case 4: text = 'Thu'; break;
                      case 5: text = 'Fri'; break;
                      case 6: text = 'Sat'; break;
                      case 7: text = 'Sun'; break;
                    }
                  } else {
                    switch (value.toInt()) {
                      case 1: text = 'J'; break;
                      case 3: text = 'M'; break;
                      case 5: text = 'M'; break;
                      case 7: text = 'J'; break;
                      case 9: text = 'S'; break;
                      case 11: text = 'N'; break;
                    }
                  }
                  return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)));
                }
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<SpendingCategory, double> data) {
    final sections = data.entries.where((e) => e.value > 0).map((e) {
      return PieChartSectionData(
        value: e.value,
        title: '',
        color: Color(e.key.color),
        radius: 50,
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: sections.isEmpty
          ? const Center(
              child: Text(
                'No transactions found to categorize.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 70,
                sections: sections,
              ),
            ),
    );
  }

  Widget _buildLegend(BuildContext context, Map<SpendingCategory, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    
    return Column(
      children: data.entries.where((e) => e.value > 0).map((e) {
        final percentage = (e.value / total * 100).toStringAsFixed(1);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 14, 
                height: 14, 
                decoration: BoxDecoration(color: Color(e.key.color), shape: BoxShape.circle)
              ),
              const SizedBox(width: 16),
              Text(
                e.key.name, 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )
              ),
              const Spacer(),
              Text(
                '\$${e.value.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(e.key.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text('$percentage%', style: TextStyle(color: Color(e.key.color), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
