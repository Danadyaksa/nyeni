import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import '../../../utils/currency_helper.dart';

/// Reusable currency converter dialog
class CurrencyConverterDialog {
  static void show(BuildContext context, {int? initialAmount}) {
    String fromCurrency = 'IDR';
    String toCurrency = 'USD';
    TextEditingController amountCtrl = TextEditingController(
      text: initialAmount != null ? initialAmount.toString() : '',
    );
    String resultText = "Hasil akan muncul di sini";
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.refreshCcw, color: Color(0xFF9A3412)),
              const SizedBox(width: 8),
              Text(
                "Konversi Kurs",
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A302A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount input
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.manrope(),
                decoration: InputDecoration(
                  labelText: "Jumlah",
                  labelStyle: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF9A3412), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Currency selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: fromCurrency,
                    style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                    items: CurrencyHelper.getSupportedCurrencies()
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: GoogleFonts.manrope()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => fromCurrency = val!),
                  ),
                  const Icon(LucideIcons.arrowRightLeft, color: Color(0xFF78706A)),
                  DropdownButton<String>(
                    value: toCurrency,
                    style: GoogleFonts.manrope(color: const Color(0xFF3A302A)),
                    items: CurrencyHelper.getSupportedCurrencies()
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: GoogleFonts.manrope()),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => toCurrency = val!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Result display
              isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF9A3412))
                  : Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        resultText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Tutup",
                style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A3412),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (amountCtrl.text.isEmpty) return;
                setState(() => isLoading = true);
                try {
                  // Use external API for real-time conversion
                  final res = await http.get(
                    Uri.parse(
                      "https://api.frankfurter.app/latest?amount=${amountCtrl.text}&from=$fromCurrency&to=$toCurrency",
                    ),
                  );
                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    setState(() => resultText = "${data['rates'][toCurrency]} $toCurrency");
                  } else {
                    setState(() => resultText = "Gagal memuat kurs");
                  }
                } catch (e) {
                  setState(() => resultText = "Error jaringan");
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: Text(
                "Konversi",
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
