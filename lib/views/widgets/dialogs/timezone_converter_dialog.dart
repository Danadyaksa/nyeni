import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../utils/timezone_helper.dart';

/// Reusable timezone converter dialog
class TimezoneConverterDialog {
  static void show(BuildContext context, {String? openTime, String? closeTime}) {
    final now = DateTime.now();
    int inputHour = now.hour;
    int inputMinute = now.minute;
    String fromZone = 'WIB';

    // If openTime is provided, use it as initial value
    if (openTime != null) {
      final minutes = TimezoneHelper.parseTime(openTime);
      if (minutes != null) {
        inputHour = minutes ~/ 60;
        inputMinute = minutes % 60;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(LucideIcons.clock, color: Color(0xFF9A3412)),
                const SizedBox(width: 8),
                Text(
                  "Konversi Waktu",
                  style: GoogleFonts.ebGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A302A),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input zone section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Zone selector
                        Row(
                          children: [
                            Text(
                              'Dari:',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: const Color(0xFF78706A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: TimezoneHelper.getSupportedTimezones()
                                    .map((z) {
                                  final selected = fromZone == z;
                                  return GestureDetector(
                                    onTap: () => setState(() => fromZone = z),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFF2C3E50)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        z,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: selected ? Colors.white : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Time spinner
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTimeSpinner(
                              value: inputHour,
                              max: 23,
                              label: 'Jam',
                              onUp: () => setState(() => inputHour = (inputHour + 1) % 24),
                              onDown: () => setState(() => inputHour = (inputHour - 1 + 24) % 24),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: GoogleFonts.manrope(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            _buildTimeSpinner(
                              value: inputMinute,
                              max: 59,
                              label: 'Menit',
                              onUp: () => setState(() => inputMinute = (inputMinute + 1) % 60),
                              onDown: () => setState(() => inputMinute = (inputMinute - 1 + 60) % 60),
                            ),
                            const SizedBox(width: 12),
                            // Reset button
                            GestureDetector(
                              onTap: () {
                                final n = DateTime.now();
                                setState(() {
                                  inputHour = n.hour;
                                  inputMinute = n.minute;
                                  fromZone = 'WIB';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.refreshCcw,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Conversion results
                  ...TimezoneHelper.getSupportedTimezones().map((zone) {
                    final isSource = zone == fromZone;
                    final inputMinutes = inputHour * 60 + inputMinute;
                    final convertedMinutes = TimezoneHelper.convertFromWIB(inputMinutes, zone);
                    final convertedTime = TimezoneHelper.formatTime(convertedMinutes);
                    
                    return Column(
                      children: [
                        _buildTimeRow(
                          zone,
                          TimezoneHelper.getTimezoneName(zone),
                          convertedTime,
                          highlight: isSource,
                        ),
                        if (zone != TimezoneHelper.getSupportedTimezones().last)
                          const Divider(height: 12),
                      ],
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Tutup",
                  style: GoogleFonts.manrope(color: const Color(0xFF78706A)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildTimeSpinner({
    required int value,
    required int max,
    required String label,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onUp,
          child: const Icon(LucideIcons.chevronUp, size: 20, color: Color(0xFF2C3E50)),
        ),
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        GestureDetector(
          onTap: onDown,
          child: const Icon(LucideIcons.chevronDown, size: 20, color: Color(0xFF2C3E50)),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 9, color: const Color(0xFF78706A)),
        ),
      ],
    );
  }

  static Widget _buildTimeRow(
    String title,
    String sub,
    String time, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF3A302A),
                    ),
                  ),
                  if (highlight) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'input',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                sub,
                style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF78706A)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlight ? Colors.blue : const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
