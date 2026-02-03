import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AIService {
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';

  static Future<Map<String, dynamic>> analyseInvoice(PlatformFile file) async {
    if (_apiKey == null) {
      throw Exception("Clé API Gemini non trouvée. Veuillez vérifier votre fichier .env.");
    }

    final uri = Uri.parse('$_url?key=$_apiKey');
    final request = http.Request('POST', uri);
    
    request.headers['Content-Type'] = 'application/json';

    final prompt = """
    Vous êtes un expert en comptabilité et un spécialiste de l'extraction de données à partir de documents. Analysez l'image ou le PDF du document ci-joint (demande d'achat, devis, etc.) et extrayez les informations suivantes. Répondez IMPÉRATIVEMENT et UNIQUEMENT avec un objet JSON valide, sans aucun formatage supplémentaire comme les démarqueurs '```json'.

    Le JSON doit avoir la structure suivante :
    {
      "supplierName": "<Nom du fournisseur>",
      "purchaseDate": "<Date de l'achat au format AAAA-MM-JJ>",
      "items": [
        {
          "description": "<Description de l'article 1>",
          "quantity": <Quantité en nombre (int)>,
          "unitPrice": <Prix unitaire en nombre (double)>,
          "totalPrice": <Prix total en nombre (double)>
        },
        {
          "description": "<Description de l'article 2>",
          "quantity": <Quantité en nombre (int)>,
          "unitPrice": <Prix unitaire en nombre (double)>,
          "totalPrice": <Prix total en nombre (double)>
        }
      ]
    }

    Instructions importantes :
    - Si une information n'est pas trouvée, retournez une chaîne de caractères vide "" pour 'supplierName' et 'purchaseDate', et une liste vide [] pour 'items'.
    - Assurez-vous que tous les nombres sont des types numériques valides (int/double) et non des chaînes de caractères.
    - Ne retournez que le JSON. Pas de texte explicatif avant ou après.
    """;

    String mimeType = _getMimeType(file.extension ?? '');
    String base64File = base64Encode(file.bytes!);

    request.body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": mimeType,
                "data": base64File
              }
            }
          ]
        }
      ]
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final text = responseBody['candidates'][0]['content']['parts'][0]['text'] as String;
      
      // Clean the response to ensure it's a valid JSON string
      final jsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } else {
      throw Exception("Erreur lors de l'analyse de la facture par l'IA: ${response.body}");
    }
  }

  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        throw Exception("Type de fichier non supporté: $extension");
    }
  }
}
