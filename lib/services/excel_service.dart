import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/purchase.dart';

class ExcelService {
  static Future<void> shareExcelReport(List<Purchase> purchases) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rapport d\'Achats'];
    excel.delete('Sheet1'); 

    const headers = [
      'Year',
      'Month',
      'Ref DA',
      'Date',
      'Commentaire Général',
      'PU',
      'Qté',
      'Total',
      'Catégorie',
      'Sous catégorie 1',
      'Sous Catégorie 2',
      'Client',
      'Mise_AD_budget',
      'Mode_Rglt',
    ];

    // Add headers to row 1 (0-indexed)
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Style header row
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)); // Row 1 is 0-indexed row 0
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4CAF50'), // Green header
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'), // White text
        bottomBorder: Border(borderStyle: BorderStyle.Medium),
        topBorder: Border(borderStyle: BorderStyle.Medium),
        leftBorder: Border(borderStyle: BorderStyle.Medium),
        rightBorder: Border(borderStyle: BorderStyle.Medium),
      );
    }

    int currentRow = 1; // Data starts from row 2 (0-indexed)
    for (final purchase in purchases) {
      for (final item in purchase.items) {
        final parsedPaymentMethod = _parsePaymentMethodForExcel(purchase.paymentMethod);
                final row = [
                  TextCellValue(purchase.date.year.toString()),
                  TextCellValue(purchase.date.month.toString()),
                  TextCellValue(purchase.refDA ?? ''),
                  TextCellValue(DateFormat('dd/MM/yyyy').format(purchase.date)),
                  TextCellValue(purchase.comments),
                  IntCellValue(item.unitPrice),
                  DoubleCellValue(item.quantity),
                  IntCellValue(item.total),
                  TextCellValue(item.category),
                  TextCellValue(item.subCategory1),
                  TextCellValue(item.subCategory2 ?? ''), // Only subCategory2
                  TextCellValue(purchase.clientName ?? ''),
                  TextCellValue(parsedPaymentMethod.miseAdBudget),
                  TextCellValue(parsedPaymentMethod.modeRglt),
                ];
                sheet.appendRow(row);
        
                // Apply borders and alternating row colors to data cells
                for (int i = 0; i < row.length; i++) {
                  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
                  cell.cellStyle = CellStyle(
                    bottomBorder: Border(borderStyle: BorderStyle.Thin),
                    topBorder: Border(borderStyle: BorderStyle.Thin),
                    leftBorder: Border(borderStyle: BorderStyle.Thin),
                    rightBorder: Border(borderStyle: BorderStyle.Thin),
                    backgroundColorHex: (currentRow % 2 == 0) ? ExcelColor.fromHexString('#FFFFFF') : ExcelColor.fromHexString('#F0F0F0'), // White / Light grey
                  );
                                  }
                currentRow++;      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnAutoFit(i);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await FileSaver.instance.saveFile(
        name: 'Rapport_Achats_$timestamp.xlsx',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  static ({String miseAdBudget, String modeRglt}) _parsePaymentMethodForExcel(String paymentMethod) {
    final parts = paymentMethod.split('/');
    if (parts.length == 2) {
      return (miseAdBudget: parts[0].trim(), modeRglt: parts[1].trim());
    }
    return (miseAdBudget: paymentMethod.trim(), modeRglt: paymentMethod.trim());
  }
}
