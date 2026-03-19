import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';

class GeminiService {
  final GenerativeModel _textModel;
  final GenerativeModel _visionModel;

  GeminiService()
      : _textModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? 'PLACEHOLDER_GEMINI_KEY',
        ),
        _visionModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? 'PLACEHOLDER_GEMINI_KEY',
        );

  /// Get styling advice based on weather and selected items
  Future<String> getStylingAdvice(List<ClothingItem> items, String weather) async {
    try {
      if (items.isEmpty) {
        return "Please select some clothing items for styling advice.";
      }
      
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey == 'PLACEHOLDER_GEMINI_KEY') {
        return "This is a great outfit for $weather! The combination of colors works well together.";
      }

      final itemDescriptions = items.map((e) => "${e.color} ${e.type.name}").join(", ");
      const prompt = '''
You are a professional fashion stylist.
The current weather is {weather}.
The user has selected the following outfit: {items}.

Please provide a short, encouraging styling advice (maximum 3 sentences) for this outfit, 
taking the weather into account. If the outfit is not suitable for the weather, 
gently suggest what to change.
      ''';

      final content = [Content.text(prompt.replaceFirst('{weather}', weather).replaceFirst('{items}', itemDescriptions))];
      final response = await _textModel.generateContent(content);
      return response.text ?? "Looks great!";
    } catch (e) {
      // ignore: avoid_print
      print('Error getting styling advice: $e');
      return "Looks great! The colors match perfectly."; // fallback
    }
  }

  /// Analyze the realistic fit using Gemini Vision
  Future<String> analyzeFit(String basePhotoPath, List<ClothingItem> items) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey == 'PLACEHOLDER_GEMINI_KEY') {
        // Fallback if no real API key
        return "The outfit fits well and the proportions look correct.";
      }

      // Read base photo bytes
      final file = File(basePhotoPath);
      if (!await file.exists()) {
        return "Base photo not found for analysis.";
      }
      
      final imageBytes = await file.readAsBytes();
      
      final itemDescriptions = items.map((e) => "${e.color} ${e.type.name}").join(", ");
      const prompt = '''
You are an expert virtual try-on AI and fashion advisor. 
I have provided a base photo of a person and a list of garments they want to try on.

Garments: {items}

Based on the person's body type, pose, and identity in the photo, please:
1. Analyze how these specific garments would realistically fit them.
2. Provide short, professional feedback (max 3 sentences) on the fit and proportions.
3. Suggest if any layering adjustments or different sizes might be needed for a better silhouette.

Be encouraging and professional.
      ''';

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [
        Content.multi([TextPart(prompt.replaceFirst('{items}', itemDescriptions)), imagePart])
      ];
      
      final response = await _visionModel.generateContent(content);
      return response.text ?? "The outfit looks like a good match.";
      
    } catch (e) {
      // ignore: avoid_print
      print('Error analyzing fit: $e');
      return "The outfit looks like a good match for your body type."; // fallback
    }
  }
}
