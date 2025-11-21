import 'package:flutter/services.dart' show rootBundle, ByteData, Uint8List;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PdfService {

  static Future<void> generateInvoicePdf(Purchase purchase) async {
    final pdf = pw.Document();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final italicFont = await PdfGoogleFonts.openSansItalic();

    final ByteData logoByteData = await rootBundle.load('assets/images/EKIBAM.jpg');
    final Uint8List logoBytes = logoByteData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInvoiceHeader(context, purchase, logoBytes),
              pw.SizedBox(height: 30),
              _buildClientInfo(purchase),
              pw.SizedBox(height: 30),
              pw.Text('Détails de la commande :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              _buildInvoiceItemsTable(purchase),
              pw.Spacer(),
              _buildInvoiceTotals(purchase),
              pw.SizedBox(height: 40),
              _buildFooter(context),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await FileSaver.instance.saveFile(
      name: 'Facture_${purchase.requestNumber ?? timestamp}.pdf',
      bytes: pdfBytes,
      mimeType: MimeType.pdf,
    );
  }

  static pw.Widget _buildInvoiceHeader(pw.Context context, Purchase purchase, Uint8List logoBytes) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(pw.MemoryImage(logoBytes), height: 60),
            pw.SizedBox(height: 10),
            pw.Text('EKIBAM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Cuisines, Rangements & plus...'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("DEMANDE D'ACHATS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 28, color: PdfColors.blueGrey800)),
            pw.SizedBox(height: 10),
            pw.Text('N°: ${purchase.requestNumber ?? 'N/A'}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(purchase.date)}'),
            pw.Text('Créé par: ${purchase.demander}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(Purchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Facturé à :', style: pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 5),
        pw.Text(
          purchase.clientName?.isNotEmpty == true ? purchase.clientName! : 'N/A (Projet ${purchase.projectType})',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceItemsTable(Purchase purchase) {
    final headers = ['Description', 'Quantité', 'Prix Unitaire', 'Total HT'];
    final data = purchase.items.map((item) {
      return [
        item.productName ?? 'N/A',
        NumberFormat('#,##0.##', 'fr_FR').format(item.quantity),
        '${NumberFormat('#,##0', 'fr_FR').format(item.unitPrice)} FCFA',
        '${NumberFormat('#,##0', 'fr_FR').format(item.quantity * item.unitPrice)} FCFA',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.all(8),
    );
  }

  static pw.Widget _buildInvoiceTotals(Purchase purchase) {
    final subtotal = purchase.items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    final fees = purchase.totalPaymentFees;
    final grandTotal = purchase.grandTotal;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              children: [
                pw.Text('Sous-total :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text('${NumberFormat('#,##0', 'fr_FR').format(subtotal)} FCFA'),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                pw.Text('Frais de paiement :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text('${NumberFormat('#,##0', 'fr_FR').format(fees)} FCFA'),
              ],
            ),
            pw.Divider(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              child: pw.Row(
                children: [
                  pw.Text('TOTAL :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(width: 20),
                  pw.Text('${NumberFormat('#,##0', 'fr_FR').format(grandTotal)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text('Merci pour votre confiance !', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text('EKIBAM SARL - EDEA, Cameroun'),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.bottomRight,
          child: pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
        )
      ],
    );
  }


  static Future<void> generatePurchaseListPdf(List<Purchase> purchases) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final ByteData logoByteData = await rootBundle.load('assets/images/EKIBAM.jpg');
    final Uint8List logoBytes = logoByteData.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.base().copyWith(
          defaultTextStyle: pw.TextStyle(font: font, fontSize: 10),
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), height: 50),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Rapport des Commandes d'Achats", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date du rapport: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(height: 20, thickness: 1),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}', style: pw.TextStyle(fontSize: 10)),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            ...purchases.map((purchase) => _buildPurchaseDetails(purchase, currencyFormat: NumberFormat('#,##0.00', 'fr_FR'))),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: 'rapport_achats.pdf',
      bytes: pdfBytes,
      mimeType: MimeType.pdf,
    );
  }

  static pw.Widget _buildPurchaseDetails(Purchase purchase, {required NumberFormat currencyFormat}) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey100,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Commande N°: ${purchase.requestNumber ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.Text('Date: ${dateFormat.format(purchase.date)}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Text('Demandeur: ${purchase.owner}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Text('Type de Projet: ${purchase.projectType}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Text('Mode de Paiement: ${purchase.paymentMethod}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              if (purchase.comments.isNotEmpty)
                pw.Text('Commentaires Généraux: ${purchase.comments}', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        _buildItemsTable(purchase.items, currencyFormat),
        pw.SizedBox(height: 5),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total Commande: ${currencyFormat.format(purchase.grandTotal)} FCFA',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<PurchaseItem> items, NumberFormat currencyFormat) {
    return pw.Table.fromTextArray(
      headers: ['Produit', 'Fournisseur', 'Quantité', 'Prix Unitaire', 'Frais', 'Total', 'Commentaire'],
      data: items.map((item) => [
        item.productName ?? 'N/A',
        item.supplierName ?? 'N/A',
        (currencyFormat.format(item.quantity)),
        (currencyFormat.format(item.unitPrice)),
        (currencyFormat.format(item.paymentFee)),
        (currencyFormat.format(item.total)),
        item.comment ?? '',
      ]).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
      cellPadding: const pw.EdgeInsets.all(4),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(2),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerLeft,
      },
    );
  }
}