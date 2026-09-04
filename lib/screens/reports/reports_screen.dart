import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../platform/file_delivery.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../../utils/date_range_utils.dart';
import '../../widgets/period_selector.dart';
import 'widgets/category_breakdown_tab.dart';
import 'widgets/trend_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _exportService = ExportService();

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

  Future<void> _pickCustomRange(AppState appState) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: appState.selectedRange.start, end: appState.selectedRange.end),
    );
    if (picked != null) {
      await appState.setRange(DateRange(picked.start, endOfDay(picked.end)));
    }
  }

  Future<void> _exportMenu(AppState appState) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Xuất CSV'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Xuất PDF'),
              onTap: () => Navigator.of(context).pop('pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final file = choice == 'csv'
        ? await _exportService.buildCsvReport(
            transactions: appState.transactionsInRange,
            categoryOf: appState.categoryById,
            walletOf: appState.walletById,
          )
        : await _exportService.buildPdfReport(
            transactions: appState.transactionsInRange,
            categoryOf: appState.categoryById,
            walletOf: appState.walletById,
            start: appState.selectedRange.start,
            end: appState.selectedRange.end,
          );
    await deliverFile(file, text: 'Báo cáo thu chi');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ'),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: () => _exportMenu(appState)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PeriodSelector(
              range: appState.selectedRange,
              onPrevious: () => appState.shiftRange(-1),
              onNext: () => appState.shiftRange(1),
              onTap: () => _pickCustomRange(appState),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Phân loại'), Tab(text: 'Xu hướng')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CategoryBreakdownTab(
                  transactions: appState.transactionsInRange,
                  categoryOf: appState.categoryById,
                ),
                TrendTab(
                  transactions: appState.transactionsInRange,
                  start: appState.selectedRange.start,
                  end: appState.selectedRange.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
