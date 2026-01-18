import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:provisions/models/purchase.dart';
import 'package:provisions/models/purchase_item.dart'; // Import PurchaseItem

class PdfService {
  static Future<void> generateInvoicePdf(Purchase purchase) async {
    final pdf = pw.Document();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final italicFont = await PdfGoogleFonts.openSansItalic();

    final ByteData logoByteData =
        await rootBundle.load('assets/images/EKIBAM.jpg');
    final Uint8List logoBytes = logoByteData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Specify A4 format
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(purchase, logoBytes),
              pw.SizedBox(height: 20), // Slightly smaller space
              _buildItemsTable(purchase),
              pw.SizedBox(height: 15),
              _buildTotals(purchase),
              pw.SizedBox(height: 15),
              _buildCommentsSection(purchase),
              pw.Spacer(),
              _buildFooter(context), // Pass context to footer for page numbers
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await FileSaver.instance.saveFile(
      name: 'Demande_Achat_${purchase.refDA ?? timestamp}.pdf',
      bytes: pdfBytes,
      mimeType: MimeType.pdf,
    );
  }

  static pw.Widget _buildHeader(Purchase purchase, Uint8List logoBytes) {
    final showDestinataire = purchase.miseADBudget != null &&
        purchase.miseADBudget!.isNotEmpty &&
        purchase.miseADBudget != purchase.demander;

    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(pw.MemoryImage(logoBytes), height: 40), // Smaller logo
              pw.SizedBox(height: 5),
              pw.Text('EKIBAM',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)), // Smaller text
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text("Demande d'Achat",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20, // Smaller title
                      color: PdfColors.indigo800)),
              pw.SizedBox(height: 8),
              pw.Text('Ref DA: ${purchase.refDA ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 10)), // Smaller text
              pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(purchase.date)}',
                  style: const pw.TextStyle(fontSize: 10)), // Smaller text
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 15),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Demandeur: ${purchase.demander}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)), // Smaller text
                pw.Text(
                    'Projet/Client: ${purchase.clientName?.isNotEmpty == true ? purchase.clientName! : purchase.projectType}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)), // Smaller text
              ]),
          if (showDestinataire) pw.SizedBox(height: 5),
          if (showDestinataire)
            pw.Text(
                'Destinataire Budget (si different demandeur): ${purchase.miseADBudget}',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ],
      ),
      pw.Divider(thickness: 0.5, height: 15), // Thinner divider
    ]);
  }

  static pw.Widget _buildItemsTable(Purchase purchase) {
    const headers = [
      'Catégorie',
      'Sous-catégorie 1',
      'Sous-catégorie 2',
      'Qté',
      'PU',
      'Total'
    ];
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2), // Category
      1: const pw.FlexColumnWidth(2.5), // SubCategory1
      2: const pw.FlexColumnWidth(3), // SubCategory2
      3: const pw.FlexColumnWidth(1), // Quantity
      4: const pw.FlexColumnWidth(1.5), // Unit Price
      5: const pw.FlexColumnWidth(1.5), // Total
    };

    final List<pw.TableRow> tableRows = [];

    // Add Header Row
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        children: headers
            .map(
              (header) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white),
                ),
              ),
            )
            .toList(),
      ),
    );

    // Add Data Rows
    for (int i = 0; i < purchase.items.length; i++) {
      final item = purchase.items[i];
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i % 2 == 0 ? PdfColors.blueGrey50 : PdfColors.white, // Alternating row colors
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.subCategory1, style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.subCategory2 ?? '', style: const pw.TextStyle(fontSize: 8))),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(item.quantity.toString(), style: const pw.TextStyle(fontSize: 8)),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(NumberFormat('#,##0', 'fr_FR').format(item.unitPrice), style: const pw.TextStyle(fontSize: 8)),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(NumberFormat('#,##0', 'fr_FR').format(item.total), style: const pw.TextStyle(fontSize: 8)),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );
  }

  static pw.Widget _buildTotals(Purchase purchase) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('Montant total général de la demande:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // Smaller text
          pw.SizedBox(width: 10),
          pw.Text(
              '${NumberFormat('#,##0', 'fr_FR').format(purchase.grandTotal)} XAF',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // Smaller text
        ],
      ),
    );
  }

  static pw.Widget _buildCommentsSection(Purchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(height: 15, thickness: 0.5), // Thinner divider
        pw.Text('Commentaires',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), // Smaller text
        pw.SizedBox(height: 5),
        if (purchase.comments.isNotEmpty)
          pw.Text('Commentaire: ${purchase.comments}',
              style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)), // Smaller text
        pw.SizedBox(height: 5),
        pw.Text('Par article:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)), // Smaller text
        ...purchase.items
            .where((item) => item.comment != null && item.comment!.isNotEmpty)
            .map(
              (item) => pw.Text(
                  '- ${item.category}/${item.subCategory1}${item.subCategory2 != null ? '/${item.subCategory2}' : ''}: ${item.comment}',
                  style: const pw.TextStyle(fontSize: 8)), // Smaller text
            ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 0.5), // Thinner divider
        pw.SizedBox(height: 5),
        pw.Text("EKIBAM SARL - EDEA, Cameroun", style: const pw.TextStyle(fontSize: 8)), // Smaller text
        pw.SizedBox(height: 5),
        pw.Align(
          alignment: pw.Alignment.bottomRight,
          child: pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)), // Smaller text
        )
      ],
    );
  }
}