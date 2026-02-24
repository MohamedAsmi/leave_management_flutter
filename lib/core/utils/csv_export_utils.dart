import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart' as web_downloader;

class CsvExportUtils {
  static Future<void> exportAndShareReport(
    List<Map<String, dynamic>> reportData,
    String reportName,
  ) async {
    // 1. Prepare CSV headers
    List<List<dynamic>> rows = [
      [
        'User Name',
        'Email',
        'Phone',
        'Total Work Days',
        'Total Work Hours',
        'Leaves Taken',
        'Half Leaves',
        'Short Leaves'
      ]
    ];

    // 2. Add rows
    for (var report in reportData) {
      rows.add([
        report['user_name'] ?? '',
        report['email'] ?? '',
        report['phone'] ?? '',
        report['total_days'] ?? 0,
        report['total_hours'] ?? 0,
        report['leaves_taken'] ?? 0,
        report['half_leaves'] ?? 0,
        report['short_leaves'] ?? 0,
      ]);
    }

    // 3. Convert to CSV string
    String csvData = rows.map((row) => row.join(',')).join('\n');

    // 4. Save and share the file
    if (kIsWeb) {
      // On Web, use an HTML Anchor to download the file directly to the computer
      // This avoids share_plus missing plugin exceptions and Web Share API limitations on desktop.
      final bytes = utf8.encode(csvData);
      web_downloader.downloadCsvFile(bytes, '$reportName.csv');
    } else {
      // On Mobile, write to temporary directory before sharing natively
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$reportName.csv');
      await file.writeAsString(csvData);

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Here is the $reportName report',
      );
    }
  }
}
