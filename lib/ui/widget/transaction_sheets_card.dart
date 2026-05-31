import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';

import '../../common/utils/formatter.dart';
import '../../domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

class TransactionCardSheets extends StatefulWidget {
  final List<TransactionEntity> incomeTransactions;
  final List<TransactionEntity> expenseTransactions;
  final Function(String id) onDelete;

  final Function(TransactionEntity transaction) onEdit;

  final Command1<void, Failure, TransactionEntity> undoDelete;
  final BuildContext scaffoldContext;

  const TransactionCardSheets({
    super.key,
    required this.incomeTransactions,
    required this.expenseTransactions,
    required this.onDelete,
    required this.onEdit, // Requerido no construtor
    required this.undoDelete,
    required this.scaffoldContext,
  });

  @override
  State<TransactionCardSheets> createState() => _TransactionCardSheetsState();
}

class _TransactionCardSheetsState extends State<TransactionCardSheets>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controlador para o TabBar e TabBarView

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    _buildTab(
                      TransactionType.income.namePlural,
                      Icons.arrow_upward,
                      0,
                      colorScheme.primary, // Cor ativa
                      colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    _buildTab(
                      TransactionType.expense.namePlural,
                      Icons.arrow_downward,
                      1,
                      colorScheme.secondary,
                      colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ],
                  indicatorColor:
                      _tabController.index == 0
                          ? colorScheme.primary
                          : colorScheme.secondary,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 290,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(
                        context,
                        widget.incomeTransactions,
                        colorScheme.primary,
                        TransactionType.income.namePlural,
                      ),
                      _buildTransactionList(
                        context,
                        widget.expenseTransactions,
                        colorScheme.secondary,
                        TransactionType.expense.namePlural,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    IconData icon,
    int index,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _tabController.index == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title, // Texto da aba
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<TransactionEntity> transactions,
    Color color,
    String title,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title ==
                      TransactionType
                          .income
                          .namePlural // Receitas
                  ? Icons.savings
                  : Icons.shopping_cart,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Sem ${title.toLowerCase()} registradas',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final undoTransaction = transaction.copyWith();

          return Dismissible(
            key: Key(transaction.id),
            direction: DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                widget.onEdit(transaction);
                return false;
              }
              return true;
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              decoration: BoxDecoration(
                color: Colors.blue, // Fundo azul para edição
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) async {
              final messenger = ScaffoldMessenger.of(widget.scaffoldContext);

              await widget.onDelete(transaction.id);

              messenger.clearSnackBars();

              messenger.showSnackBar(
                SnackBar(
                  content: Text('${transaction.title} excluída!!!'),
                  backgroundColor: Colors.pinkAccent,
                  action: SnackBarAction(
                    label: 'DESFAZER',
                    textColor: Colors.white,
                    onPressed: () async {
                      await widget.undoDelete.execute(undoTransaction);

                      if (widget.undoDelete.resultSignal.value?.isSuccess ??
                          false) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${transaction.title} restaurada!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        final errorMessage =
                            widget
                                .undoDelete
                                .resultSignal
                                .value
                                ?.failureValueOrNull
                                ?.toString();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(errorMessage ?? 'Erro desconhecido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    title == TransactionType.income.namePlural
                        ? Icons.attach_money
                        : Icons.shopping_bag,
                    color: color,
                  ),
                ),
                title: Text(
                  transaction.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  Formatter.formatDate(transaction.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  Formatter.formatCurrency(transaction.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
