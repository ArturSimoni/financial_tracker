import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';

import 'transaction_form.dart';

class TransactionSheet extends StatelessWidget {
  final TransactionType type;

  final Command1<void, Failure, TransactionEntity> submitCommand;

  final TransactionEntity? transaction;

  const TransactionSheet({
    super.key,
    required this.type,
    required this.submitCommand,
    this.transaction,
  });

  static Future<void> show({
    required BuildContext context,
    required TransactionType type,
    required Command1<void, Failure, TransactionEntity> submitCommand,
    TransactionEntity? transaction,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TransactionSheet(
            type: type,
            submitCommand: submitCommand,
            transaction: transaction,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIncome = type == TransactionType.income;
    final color = isIncome ? colorScheme.primary : colorScheme.secondary;
    final formTitle = type.nameSingular;

    final isEditing = transaction != null;
    final displayTitle =
        isEditing ? 'Editar $formTitle' : 'Adicionar $formTitle';

    final availableHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: availableHeight,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Título do cabeçalho mudando conforme a ação
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit_note
                            : (isIncome
                                ? Icons.trending_up
                                : Icons.trending_down),
                        color: colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: TransactionForm(
                  type: type,
                  color: color,
                  submitCommand: submitCommand,
                  transaction: transaction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
