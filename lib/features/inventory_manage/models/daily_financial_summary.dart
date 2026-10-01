import '../utils/money_format.dart';

class DailyFinancialSummary {
  final double invoicesTotal;
  final double paymentsReceived;
  final double outstanding;
  final double expenses;
  final double netCashFlow;

  const DailyFinancialSummary({
    required this.invoicesTotal,
    required this.paymentsReceived,
    required this.outstanding,
    required this.expenses,
    required this.netCashFlow,
  });

  static const zero = DailyFinancialSummary(
    invoicesTotal: 0,
    paymentsReceived: 0,
    outstanding: 0,
    expenses: 0,
    netCashFlow: 0,
  );

  String get invoicesLabel => formatMoney(invoicesTotal);
  String get paymentsLabel => formatMoney(paymentsReceived);
  String get outstandingLabel => formatMoney(outstanding);
  String get expensesLabel => formatMoney(expenses);
  String get netLabel => formatMoney(netCashFlow);

  bool get isProfit => netCashFlow >= 0;
}

class DailyPeriodFilterSummary {
  final double paymentsTotal;
  final double expensesTotal;
  final double netTotal;
  final int paymentsCount;
  final int outputsCount;

  const DailyPeriodFilterSummary({
    required this.paymentsTotal,
    required this.expensesTotal,
    required this.netTotal,
    required this.paymentsCount,
    required this.outputsCount,
  });

  static const empty = DailyPeriodFilterSummary(
    paymentsTotal: 0,
    expensesTotal: 0,
    netTotal: 0,
    paymentsCount: 0,
    outputsCount: 0,
  );
}
