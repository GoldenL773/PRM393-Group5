import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/models/outfit.dart';

class GeminiService {
  final GenerativeModel _textModel;
  final GenerativeModel _visionModel;
  
  // Base URL for direct REST API calls when SDK lacks feature support
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiService()
      : _textModel = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY_TEXT'] ?? dotenv.env['GEMINI_API_KEY'] ?? 'PLACEHOLDER_GEMINI_KEY',
        ),
        _visionModel = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY_TEXT'] ?? dotenv.env['GEMINI_API_KEY'] ?? 'PLACEHOLDER_GEMINI_KEY',
        );

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? 'PLACEHOLDER_GEMINI_KEY';
  String get _textApiKey => dotenv.env['GEMINI_API_KEY_TEXT'] ?? _apiKey;

  /// Helper for sending raw HTTP requests with responseModalities
  Future<String?> _generateImageViaRest(String model, Map<String, dynamic> requestBody) async {
    if (_apiKey == 'PLACEHOLDER_GEMINI_KEY') {
      print('DEBUG: Gemini API Key is missing or placeholder!');
      return null; // Fallback
    }

    print('DEBUG: Calling Gemini API model: $model');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final inlineData = parts.firstWhere(
              (p) => p['inlineData'] != null,
              orElse: () => null,
            );
            if (inlineData != null) {
              print('DEBUG: Gemini API successfully returned an image inlineData.');
              return inlineData['inlineData']['data'] as String; // Base64
            }
            
            // If it returned text instead of image
            final textPart = parts.firstWhere(
              (p) => p['text'] != null,
              orElse: () => null,
            );
            if (textPart != null) {
              final text = textPart['text'] as String;
              print('DEBUG: Gemini API returned text instead of image: $text');
              throw Exception('Gemini returned text instead of image: $text');
            }
          }
        }
        print('DEBUG: No inlineData found in response: ${response.body}');
        throw Exception('No image data found in response.');
      } else {
        print('DEBUG: Gemini API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error calling Gemini REST API: $e');
    }
    return null;
  }

  /// Standardize Model Photo
  /// Converts the user's uploaded photo into a standard, clean, full-body studio pose.
  Future<String?> generateModelImage(String originalImagePath) async {
    try {
      final file = File(originalImagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();

      final requestBody = {
        "contents": [
          {
            "parts": [
              {"inlineData": {"mimeType": "image/jpeg", "data": base64Encode(bytes)}},
              {
                "text": "You are an expert fashion photographer AI. Transform the person in this image into a full-body fashion model photo suitable for an e-commerce website. The background must be a clean, neutral studio backdrop (light gray, #f0f0f0). The person should have a neutral, professional model expression. Preserve the person's identity, unique features, and body type, but place them in a standard, relaxed standing model pose. The final image must be photorealistic. Return ONLY the final image."
              }
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["IMAGE"]
        }
      };

      return await _generateImageViaRest('gemini-2.5-flash-image', requestBody);
    } catch (e) {
      print('Model Standardization Error: $e');
      return null;
    }
  }

  /// Generate Virtual Try-On Image using gemini-2.5-flash-image
  Future<String?> generateVirtualTryOnImage(String modelImagePath, List<String> garmentImagePaths) async {
    try {
      final modelFile = File(modelImagePath);
      if (!await modelFile.exists()) return null;

      final parts = <Map<String, dynamic>>[];
      
      // Add model image
      final modelBytes = await modelFile.readAsBytes();
      parts.add({"inlineData": {"mimeType": "image/jpeg", "data": base64Encode(modelBytes)}});

      // Add garments
      for (final path in garmentImagePaths) {
        final garmentFile = File(path);
        if (await garmentFile.exists()) {
          final bytes = await garmentFile.readAsBytes();
          parts.add({"inlineData": {"mimeType": "image/jpeg", "data": base64Encode(bytes)}});
        }
      }

      // Add text prompt
      parts.add({
        "text": "You are an expert virtual try-on AI. You will be given a model image (first) and garment images (subsequent). Your task is to create a new photorealistic image where the person from the model image is wearing the clothing from the garment images.\n\n**Crucial Rules:**\n1. Complete Garment Replacement: You MUST completely REMOVE and REPLACE the existing clothing item. No part of the original clothing should be visible.\n2. Preserve the Model: The person's face, hair, body shape, and pose MUST remain unchanged.\n3. Preserve the Background: The entire background MUST be preserved perfectly.\n4. Apply the Garment: Realistically fit the new garment onto the person with natural folds, shadows, and lighting.\n5. Output: Return ONLY the final, edited image. Do not include any text."
      });

      final requestBody = {
        "contents": [
          {
            "parts": parts
          }
        ],
        "generationConfig": {
          "responseModalities": ["IMAGE"]
        }
      };

      return await _generateImageViaRest('gemini-2.5-flash-image', requestBody);
    } catch (e) {
      print('VTO Error: $e');
      return null;
    }
  }

  /// Generate Pose Variation
  Future<String?> generatePoseVariation(String baseImagePath, String poseInstruction) async {
    try {
      final file = File(baseImagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return generatePoseVariationForBase64(base64Encode(bytes), poseInstruction);
    } catch (e) {
      print('Pose Variation Error: $e');
      return null;
    }
  }

  /// Generate Pose Variation using Base64 directly
  Future<String?> generatePoseVariationForBase64(String base64Image, String poseInstruction) async {
    try {
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"inlineData": {"mimeType": "image/jpeg", "data": base64Image}},
              {
                "text": "You are an expert fashion photographer AI. Regenerate this image with a different perspective: $poseInstruction. Keep the person, clothing, and background style identical. Return ONLY the final image."
              }
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["IMAGE"]
        }
      };

      return await _generateImageViaRest('gemini-2.5-flash-image', requestBody);
    } catch (e) {
      print('Pose Variation Base64 Error: $e');
      return null;
    }
  }

  /// Background Removal
  /// Uses Remove.bg API if REMOVE_BG_API_KEY is available in .env, otherwise falls back to Gemini.
  Future<String?> removeBackground(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      
      // Try Remove.bg first
      final removeBgKey = dotenv.env['REMOVE_BG_API_KEY'];
      if (removeBgKey != null && removeBgKey.isNotEmpty && removeBgKey != 'PLACEHOLDER_REMOVE_BG_KEY') {
        print('DEBUG: Using Remove.bg API for background removal');
        final request = http.MultipartRequest('POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
        request.headers['X-Api-Key'] = removeBgKey;
        request.files.add(http.MultipartFile.fromBytes('image_file', bytes, filename: 'image.jpg'));
        request.fields['size'] = 'auto';

        final response = await request.send();
        if (response.statusCode == 200) {
          final respBytes = await response.stream.toBytes();
          return base64Encode(respBytes);
        } else {
          print('DEBUG: Remove.bg API failed with status ${response.statusCode}, falling back to Gemini.');
        }
      }

      print('DEBUG: Using Gemini API for background removal');
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"inlineData": {"mimeType": "image/jpeg", "data": base64Encode(bytes)}},
              {
                "text": "Remove the background and any person/mannequin from this image. Keep ONLY the clothing item (subject) with a completely transparent or solid white background. Return ONLY the final image."
              }
            ]
          }
        ],
        "generationConfig": {
          "responseModalities": ["IMAGE"]
        }
      };

      return await _generateImageViaRest('gemini-2.5-flash-image', requestBody);
    } catch (e) {
      print('Background Removal Error: $e');
      return null;
    }
  }

  /// Get the best outfit recommendation based on weather
  Future<String?> recommendBestOutfit(List<Outfit> outfits, Map<String, List<ClothingItem>> outfitsItems, String weather) async {
    try {
      if (outfits.isEmpty) return null;

      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY') {
        return outfits.first.id; // Fallback to first
      }

      final outfitDescriptions = outfits.map((o) {
        final items = outfitsItems[o.id] ?? [];
        final desc = items.map((e) => "${e.color} ${e.type.name}").join(", ");
        return "ID: ${o.id} - Items: $desc";
      }).join("\n");

      final prompt = '''
You are a professional fashion stylist. The current weather is $weather.
I have the following outfits available:
$outfitDescriptions

Based on the weather, please select the single best outfit ID from the list.
Return ONLY the ID of the selected outfit, nothing else.
      ''';

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      final recommendedId = response.text?.trim() ?? "";
      
      if (outfits.any((o) => o.id == recommendedId)) {
        return recommendedId;
      }
      return outfits.first.id;
    } catch (e) {
      print('Error recommending outfit: $e');
      return outfits.isNotEmpty ? outfits.first.id : null;
    }
  }
  Future<String> getStylingAdvice(List<ClothingItem> items, String weather) async {
    try {
      if (items.isEmpty) {
        return "Please select some clothing items for styling advice.";
      }
      
      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY') {
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
      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY') {
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
