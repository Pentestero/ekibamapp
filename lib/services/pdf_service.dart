import 'package:flutter/services.dart' show rootBundle, ByteData, Uint8List;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PdfService {

  static int _checkboxCounter = 0;

  static pw.Widget _checkbox(bool checked, {double size = 18}) {
    _checkboxCounter++;
    // The size parameter is ignored as pw.Checkbox in this version has a fixed size.
    return pw.Checkbox(
      name: 'cb_$_checkboxCounter',
      value: checked,
    );
  }

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
              pw.SizedBox(height: 12),
              _buildPurchaseMeta(purchase),
              pw.SizedBox(height: 12),
              _buildDestinationSection(purchase),
              pw.SizedBox(height: 24),
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
            pw.Text("DEMANDE D'ACHATS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 28, color: PdfColors.indigo800)),
            pw.SizedBox(height: 10),
            pw.Text('N°: ${purchase.requestNumber ?? 'N/A'}'),
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(purchase.date)}'),
            pw.Text('Demandé par: ${purchase.demander}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(Purchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Pour :', style: pw.TextStyle(color: PdfColors.grey600)),
        pw.SizedBox(height: 5),
        pw.Text(
          purchase.clientName?.isNotEmpty == true ? purchase.clientName! : 'N/A (Projet ${purchase.projectType})',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  static pw.Widget _buildPurchaseMeta(Purchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text('Prénom demandeur : ${purchase.demander}')),
            pw.SizedBox(width: 12),
            pw.Expanded(child: pw.Text('Destinataire budget (si différent) : ${purchase.owner}')),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('Destination : (cocher si multi clients ou si interne atelier ou consommables habituels)',style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildDestinationSection(Purchase purchase) {
    final type = purchase.projectType.toLowerCase();
    final isClient = type == 'client';
    final isMulti = type == 'mixte';
    final isInterne = type == 'interne';

    pw.Widget checkbox(bool checked) => _checkbox(checked, size: 18);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Spécifique client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Multi clients', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Interne atelier', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800))),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(height: 28, alignment: pw.Alignment.center, child: checkbox(isClient)),
            pw.Container(height: 28, alignment: pw.Alignment.center, child: checkbox(isMulti)),
            pw.Container(height: 28, alignment: pw.Alignment.center, child: checkbox(isInterne)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceItemsTable(Purchase purchase) {
    final headers = ['Désignation', 'PU', 'Qté', 'Total', 'Commentaire'];

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1.4),
      4: const pw.FlexColumnWidth(2.6),
    };

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(headers[0], style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(headers[1], style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(headers[2], style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(headers[3], style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(headers[4], style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );

    final rows = <pw.TableRow>[];
    for (var i = 0; i < purchase.items.length; i++) {
      final item = purchase.items[i];
      final designation = item.productName ?? 'N/A';
      final pu = NumberFormat('#,##0', 'fr_FR').format(item.unitPrice);
      final qte = NumberFormat('#,##0.##', 'fr_FR').format(item.quantity);
      final total = NumberFormat('#,##0', 'fr_FR').format(item.quantity * item.unitPrice);
      final comment = item.comment ?? '';

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.indigo50 : PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(designation, style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(pu, style: const pw.TextStyle(fontSize: 10))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(qte, style: const pw.TextStyle(fontSize: 10))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(total, style: const pw.TextStyle(fontSize: 10))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(comment, style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: columnWidths,
      children: [headerRow, ...rows],
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
              decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
              child: pw.Row(
                children: [
                  pw.Text('TOTAL :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.indigo800)),
                  pw.SizedBox(width: 20),
                  pw.Text('${NumberFormat('#,##0', 'fr_FR').format(grandTotal)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.indigo800)),
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
        pw.Text("L'avenir des meubles ultra moderne !", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                      pw.Text("Rapport des Commandes d'Achats", style: pw.TextStyle(fontSize: 24, font: boldFont)),
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
            color: PdfColors.indigo100,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Commande N°: ${purchase.requestNumber ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
              ),
              pw.Text('Date: ${dateFormat.format(purchase.date)}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Text('Demandeur: ${purchase.demander}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
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
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<PurchaseItem> items, NumberFormat currencyFormat) {
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(1.5),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1.2),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(1.2),
      6: const pw.FlexColumnWidth(2),
    };

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Produit', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Fournisseur', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Quantité', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Prix Unitaire', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Frais', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Total', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text('Commentaire', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
      ],
    );

    final rows = <pw.TableRow>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.indigo50 : PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Row(children: [
                _checkbox(true, size: 12),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text(item.productName ?? 'N/A', style: const pw.TextStyle(fontSize: 10))),
              ]),
            ),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Text(item.supplierName ?? 'N/A', style: const pw.TextStyle(fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.quantity), style: const pw.TextStyle(fontSize: 10)))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.unitPrice), style: const pw.TextStyle(fontSize: 10)))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.paymentFee), style: const pw.TextStyle(fontSize: 10)))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.total), style: const pw.TextStyle(fontSize: 10)))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Text(item.comment ?? '', style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: columnWidths,
      children: [headerRow, ...rows],
    );
  }
}
