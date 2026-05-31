import 'package:financial_tracker/common/errors/errors_classes.dart';
import 'package:financial_tracker/common/patterns/command.dart';
import 'package:financial_tracker/domain/entity/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

class TransactionForm extends StatefulWidget {
  final Command1<void, Failure, TransactionEntity> submitCommand;

  final TransactionType type;

  final Color color;

  final TransactionEntity? transaction;

  const TransactionForm({
    super.key,
    required this.type,
    required this.color,
    required this.submitCommand,
    this.transaction,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text =
          tx.amount % 1 == 0
              ? tx.amount.toInt().toString()
              : tx.amount.toString();
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final enteredTitle = _titleController.text;
      final enteredAmount = double.parse(_amountController.text);

      final String actionName = _isEditing ? 'atualizar' : 'adicionar';
      final String successName = _isEditing ? 'Atualizada' : 'Adicionada';

      final transactionData =
          _isEditing
              ? widget.transaction!.copyWith(
                title: enteredTitle,
                amount: enteredAmount,
                date: _selectedDate,
                type: widget.type,
              )
              : TransactionEntity(
                title: enteredTitle,
                amount: enteredAmount,
                date: _selectedDate,
                type: widget.type,
              );

      await widget.submitCommand.execute(transactionData);

      if (!mounted) return;

      if (widget.submitCommand.resultSignal.value?.isFailure ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao $actionName ${widget.type.nameSingular}: ${widget.submitCommand.resultSignal.value?.failureValueOrNull ?? 'Erro desconhecido'}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        return;
      }

      if (!_isEditing) {
        _titleController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.type.nameSingular} $successName com Sucesso!',
          ),
          backgroundColor: widget.color,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe uma descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de entrada para o valor
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe um valor';
                }
                if (double.tryParse(value) == null) {
                  return 'Digite um número válido';
                }
                if (double.parse(value) <= 0) {
                  return 'O valor deve ser maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: Text(
                    'Selecionar Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Watch((context) {
              final isRunning = widget.submitCommand.runningSignal.value;

              return SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isRunning ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isRunning
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            _isEditing
                                ? 'Salvar Alterações'
                                : 'Adicionar ${widget.type.nameSingular}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
