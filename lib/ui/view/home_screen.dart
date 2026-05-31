import '../../common/config/dependencies.dart';
import '../../common/types/date_filter_type.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:financial_tracker/ui/controller/home_page_controller.dart';
import 'package:financial_tracker/ui/widget/date_filter_transactions.dart';
import 'package:financial_tracker/ui/widget/summary_carousel.dart';
import 'package:financial_tracker/ui/widget/transaction_sheet.dart';
import 'package:financial_tracker/ui/widget/transaction_sheets_card.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomePageController viewModelController;
  bool _isFilterVisible = false;

  @override
  void initState() {
    viewModelController = injector.get<HomePageController>();
    viewModelController.load.execute();
    super.initState();
  }

  void _toggleFilterVisibility() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Controle Financeiro',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          Watch((context) {
            final isVisible = viewModelController.isFilterVisible.value;
            return IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, anim) => RotationTransition(
                      turns: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                child: Icon(
                  isVisible ? Icons.filter_list_off : Icons.filter_list,
                  key: ValueKey(isVisible),
                ),
              ),
              tooltip: isVisible ? 'Ocultar filtros' : 'Mostrar filtros',
              onPressed: viewModelController.toggleFilterVisibility,
            );
          }),
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {},
            tooltip: 'Visualizar todas as transações',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Watch((context) {
                    final income = viewModelController.totalIncome.value;
                    final expense = viewModelController.totalExpense.value;
                    return SummaryCarousel(
                      totalIncome: income,
                      totalExpense: expense,
                    );
                  }),
                ),
              ],
            ),

            Watch((context) {
              final isVisible = viewModelController.isFilterVisible.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                margin:
                    isVisible
                        ? const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        )
                        : EdgeInsets.zero,
                height: isVisible ? null : 0,
                child:
                    isVisible
                        ? Card(
                          elevation: 4,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: DateFilterTransactions(
                              filtro: (
                                type: viewModelController.filterType,
                                startDate: viewModelController.startDate,
                                endDate: viewModelController.endDate,
                              ),
                              onFilterChanged: (startDate, endDate) {
                                viewModelController.searchTransactionsByDate
                                    .execute(startDate!, endDate!);
                              },
                              onUpdateFilter: (type, startDate, endDate) {
                                viewModelController.setFiltersParams(
                                  type,
                                  startDate,
                                  endDate,
                                );
                              },
                              onAllTransactionsFiltered: () {
                                viewModelController.load.execute();
                              },
                              onTapHideFilter: _toggleFilterVisibility,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              );
            }),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context: context,
                          title: 'Nova Receita',
                          subtitle: 'Adicionar ganhos',
                          icon: Icons.arrow_upward_rounded,
                          startColor: const Color(0xFF00B48B),
                          endColor: const Color(0xFF00E676),
                          onTap: () => _showIncomeSheet(context),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildActionCard(
                          context: context,
                          title: 'Nova Despesa',
                          subtitle: 'Registrar gastos',
                          icon: Icons.arrow_downward_rounded,
                          startColor: const Color(0xFFFF5252),
                          endColor: const Color(0xFFFF1744),
                          onTap: () => _showExpenseSheet(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Watch((context) {
                final incomes = viewModelController.incomes.value;
                final expenses = viewModelController.expenses.value;
                return TransactionCardSheets(
                  incomeTransactions: incomes,
                  expenseTransactions: expenses,
                  onDelete: (id) {
                    viewModelController.deleteTransaction.execute(id);
                  },
                  undoDelete: viewModelController.undoDelectedTransaction,
                  scaffoldContext: context,
                  onEdit: (transaction) {
                    _showEditSheet(context, transaction);
                  },
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncomeSheet(BuildContext context) {
    TransactionSheet.show(
      context: context,
      type: TransactionType.income,
      submitCommand: viewModelController.saveTransaction,
    );
  }

  void _showExpenseSheet(BuildContext context) {
    TransactionSheet.show(
      context: context,
      type: TransactionType.expense,
      submitCommand: viewModelController.saveTransaction,
    );
  }

  void _showEditSheet(BuildContext context, TransactionEntity transaction) {
    TransactionSheet.show(
      context: context,
      type: transaction.type,
      transaction: transaction,
      submitCommand: viewModelController.saveTransaction,
    );
  }
}
