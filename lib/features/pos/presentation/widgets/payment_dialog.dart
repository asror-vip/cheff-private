import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(Map<String, double> payments) onConfirm;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  double _cash = 0.0;
  double _card = 0.0;
  double _transfer = 0.0;

  String _activeMethod = 'cash'; // 'cash', 'card', 'transfer'
  String _currentInput = '';

  double get _totalEntered => _cash + _card + _transfer;
  double get _remaining => widget.totalAmount - _totalEntered;

  @override
  void initState() {
    super.initState();
    _cash = widget.totalAmount;
    _currentInput = _cash.toStringAsFixed(0);
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == 'C') {
        _currentInput = '';
      } else if (value == 'EXACT') {
        _currentInput = (_remaining > 0 ? _remaining : 0).toStringAsFixed(0);
      } else {
        if (_currentInput == '0') _currentInput = '';
        _currentInput += value;
      }
      _updateActiveAmount();
    });
  }

  void _updateActiveAmount() {
    final val = double.tryParse(_currentInput) ?? 0.0;
    if (_activeMethod == 'cash') _cash = val;
    if (_activeMethod == 'card') _card = val;
    if (_activeMethod == 'transfer') _transfer = val;
  }

  void _setActiveMethod(String method) {
    setState(() {
      _activeMethod = method;
      if (method == 'cash') _currentInput = _cash == 0 ? '' : _cash.toStringAsFixed(0);
      if (method == 'card') _currentInput = _card == 0 ? '' : _card.toStringAsFixed(0);
      if (method == 'transfer') _currentInput = _transfer == 0 ? '' : _transfer.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'common.currency_sum'.tr();
    final NumberFormat formatter = NumberFormat.currency(locale: 'uz', symbol: currency, decimalDigits: 0);

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 550,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Left Side: Payment Details
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'To\'lov qabul qilish',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  
                  // Total Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Text('Jami to\'lov:', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(widget.totalAmount),
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods
                  _buildPaymentRow('cash', 'Naqd pul', Icons.money, Colors.green, _cash, formatter),
                  const SizedBox(height: 12),
                  _buildPaymentRow('card', 'Plastik karta', Icons.credit_card, Colors.blue, _card, formatter),
                  const SizedBox(height: 12),
                  _buildPaymentRow('transfer', 'O\'tkazma', Icons.sync_alt, Colors.purpleAccent, _transfer, formatter),

                  const Spacer(),
                  // Remaining / Change
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _remaining < 0 ? AppColors.warning.withOpacity(0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _remaining < 0 ? 'Qaytim:' : 'Qoldi:',
                          style: TextStyle(
                            color: _remaining < 0 ? AppColors.warning : AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatter.format(_remaining.abs()),
                          style: TextStyle(
                            color: _remaining == 0 
                                ? AppColors.success 
                                : (_remaining < 0 ? AppColors.warning : AppColors.error),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            const VerticalDivider(color: Colors.white10, thickness: 1, width: 1),
            const SizedBox(width: 32),
            // Right Side: Numpad & Actions
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumpadRow(['1', '2', '3']),
                        _buildNumpadRow(['4', '5', '6']),
                        _buildNumpadRow(['7', '8', '9']),
                        _buildNumpadRow(['C', '0', '00']),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _onNumpadTap('EXACT'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 65,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Text('Qoldiqni to\'lash', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _remaining <= 0 
                            ? () {
                                final Map<String, double> payments = {};
                                if (_cash > 0) payments['cash'] = _cash;
                                if (_card > 0) payments['card'] = _card;
                                if (_transfer > 0) payments['transfer'] = _transfer;
                                
                                if (_remaining < 0 && payments.containsKey('cash')) {
                                  payments['cash'] = payments['cash']! + _remaining; 
                                }
                                widget.onConfirm(payments);
                              }
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: AppColors.success.withOpacity(0.3),
                          ),
                          child: const Text('To\'lash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String method, String title, IconData icon, Color iconColor, double amount, NumberFormat formatter) {
    final isActive = _activeMethod == method;
    return InkWell(
      onTap: () => _setActiveMethod(method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? iconColor.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? iconColor : Colors.white10, width: isActive ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            const Spacer(),
            Text(
              formatter.format(amount),
              style: TextStyle(
                color: amount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      children: keys.map((k) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: InkWell(
            onTap: () => _onNumpadTap(k),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 65,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k == 'C' ? AppColors.error.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                k,
                style: TextStyle(
                  color: k == 'C' ? AppColors.error : AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}
