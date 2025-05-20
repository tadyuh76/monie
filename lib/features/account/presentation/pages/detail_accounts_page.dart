import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import '../../../home/domain/entities/account.dart';
import '../../../transactions/domain/entities/transaction.dart';
import 'item_transaction.dart';

class DetailAccountsPage extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;

  const DetailAccountsPage({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  State<DetailAccountsPage> createState() => _DetailAccountsPageState();
}

class _DetailAccountsPageState extends State<DetailAccountsPage> {
  Account get account => widget.account;

  List<Transaction> get transactions => widget.transactions;
  Map<String, double> dataMap = {};

  final colorList = <Color>[
    const Color(0xfffdcb6e),
    const Color(0xff0984e3),
    const Color(0xfffd79a8),
    const Color(0xffe17055),
    const Color(0xff6c5ce7),
  ];

  final ChartType _chartType = ChartType.disc;
  final double _ringStrokeWidth = 32;
  final double _chartLegendSpacing = 32;

  final bool _showLegendsInRow = false;
  final bool _showLegends = true;

  final bool _showChartValueBackground = true;
  final bool _showChartValues = true;
  final bool _showChartValuesInPercentage = false;
  final bool _showChartValuesOutside = false;

  final LegendPosition _legendPosition = LegendPosition.right;

  int key = 0;

  @override
  void initState() {
    super.initState();
    dataMap = <String, double>{
      "Balance": (account.balance ?? 0.0),
      "Transaction": account.transactionCount?.toDouble() ?? 1.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Details Account', style: TextStyle(color: Colors.white)),
        backgroundColor: account.getColor(),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        color: Colors.black54,
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Text(
              account.name ?? '',
              maxLines: 1,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: (account.getColor()).withAlpha(50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Account Total',
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${account.balance}${account.currency}',
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${account.transactionCount} transactions',
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            PieChart(
              key: ValueKey(key),
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: _chartLegendSpacing,
              chartRadius: math.min(
                MediaQuery.of(context).size.width / 3.2,
                300,
              ),
              colorList: colorList.sublist(0),
              initialAngleInDegree: 0,
              chartType: _chartType,
              legendOptions: LegendOptions(
                showLegendsInRow: _showLegendsInRow,
                legendPosition: _legendPosition,
                showLegends: _showLegends,
                legendShape: BoxShape.circle,
                legendTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              chartValuesOptions: ChartValuesOptions(
                showChartValueBackground: _showChartValueBackground,
                showChartValues: _showChartValues,
                showChartValuesInPercentage: _showChartValuesInPercentage,
                showChartValuesOutside: _showChartValuesOutside,
              ),
              ringStrokeWidth: _ringStrokeWidth,
              emptyColor: Colors.grey,
              emptyColorGradient: const [Color(0xff6c5ce7), Colors.blue],
              baseChartColor: Colors.transparent,
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: (account.getColor()).withAlpha(50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'View All Transaction',
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  transactions.isEmpty
                      ? Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: EdgeInsets.only(top: 50),
                          child: Text(
                            'Not found transaction!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return ItemTransactionCard(
                            transaction: transactions[index],
                            account: account,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
