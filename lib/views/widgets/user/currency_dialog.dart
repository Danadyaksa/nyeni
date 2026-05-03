import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog untuk konversi harga ke mata uang lain
class CurrencyDialog extends StatefulWidget {
  final int priceIdr;

  const CurrencyDialog({
    super.key,
    required this.priceIdr,
  });

  static void show(BuildContext context, {required int priceIdr}) {
    showDialog(
      context: context,
      builder: (ctx) => CurrencyDialog(priceIdr: priceIdr),
    );
  }

  @override
  State<CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<CurrencyDialog> {
  String toCurrency = 'USD';
  String resultText = 'Tap Konversi';
  bool isLoading = false;

  final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'SGD', 'MYR', 'AUD'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(LucideIcons.refreshCcw, color: Colors.green),
        SizedBox(width: 8),
        Text('Konversi Harga Tiket'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // IDR Price
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text('Harga dalam IDR',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text(
                  'Rp ${_fmtPrice(widget.priceIdr)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF2C3E50)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Currency selector
          Row(
            children: [
              const Text('Konversi ke:',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: toCurrency,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => toCurrency = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Result
          isLoading
              ? const CircularProgressIndicator(color: Color(0xFF2C3E50))
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    resultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green),
                  ),
                ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _convertCurrency,
          child: const Text('Konversi',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _convertCurrency() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://api.frankfurter.app/latest?amount=${widget.priceIdr}&from=IDR&to=$toCurrency'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rate = data['rates'][toCurrency];
        setState(() => resultText = '$rate $toCurrency');
      } else {
        setState(() => resultText = 'Gagal memuat kurs');
      }
    } catch (e) {
      setState(() => resultText = 'Error jaringan');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _fmtPrice(dynamic price) {
    final p = (price is int)
        ? price
        : (double.tryParse(price.toString()) ?? 0).toInt();
    return p
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
