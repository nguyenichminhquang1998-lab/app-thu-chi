import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_entry.dart';
import '../../state/app_state.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction_detail/transaction_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<TxEntry> _results = [];
  bool _searched = false;

  Future<void> _search(AppState appState) async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    final results = await appState.searchTransactions(query);
    setState(() {
      _results = results;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm theo ghi chú hoặc chủ đề...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(appState),
          onChanged: (_) => _search(appState),
        ),
      ),
      body: !_searched
          ? const Center(child: Text('Nhập từ khoá để tìm giao dịch'))
          : _results.isEmpty
              ? const Center(child: Text('Không tìm thấy giao dịch nào'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final tx = _results[index];
                    return TransactionTile(
                      transaction: tx,
                      category: appState.categoryById(tx.categoryId),
                      wallet: appState.walletById(tx.walletId),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
                      ),
                    );
                  },
                ),
    );
  }
}
