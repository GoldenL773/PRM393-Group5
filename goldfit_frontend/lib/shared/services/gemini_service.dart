import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:goldfit_frontend/shared/models/clothing_item.dart';
import 'package:goldfit_frontend/shared/utils/error_logger.dart';

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

    // ignore: avoid_print
    print('DEBUG: Calling Gemini API model: $model');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // ignore: avoid_print
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
              // ignore: avoid_print
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
              // ignore: avoid_print
              print('DEBUG: Gemini API returned text instead of image: $text');
              throw Exception('Gemini returned text instead of image: $text');
            }
          }
        }
        // ignore: avoid_print
        print('DEBUG: No inlineData found in response: ${response.body}');
        throw Exception('No image data found in response.');
      } else {
        // ignore: avoid_print
        print('DEBUG: Gemini API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
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
        "text": "You are an expert virtual try-on AI. You will be given a 'model image' and a 'garment image'. Your task is to create a new photorealistic image where the person from the 'model image' is wearing the clothing from the 'garment image'.\n\n**Crucial Rules:**\n1.  **Complete Garment Replacement:** You MUST completely REMOVE and REPLACE the clothing item worn by the person in the 'model image' with the new garment. No part of the original clothing (e.g., collars, sleeves, patterns) should be visible in the final image.\n2.  **Preserve the Model:** The person's face, hair, body shape, and pose from the 'model image' MUST remain unchanged.\n3.  **Preserve the Background:** The entire background from the 'model image' MUST be preserved perfectly.\n4.  **Apply the Garment:** Realistically fit the new garment onto the person. It should adapt to their pose with natural folds, shadows, and lighting consistent with the original scene.\n5.  **Output:** Return ONLY the final, edited image. Do not include any text."
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
  /// Uses Remove.bg API strictly.
  Future<String?> removeBackground(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      
      // Use Remove.bg API token directly as requested by the user
      final removeBgKey = dotenv.env['REMOVE_BG_API_KEY'] ?? 'vhooNUm1h6akn3RmiSG8eMfP';
      
      // ignore: avoid_print
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
        // ignore: avoid_print
        print('DEBUG: Remove.bg API failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Background Removal Error: $e');
      return null;
    }
  }

  /// Get structured outfit recommendation categories/seasons based on weather using Gemini text model
  Future<String?> getStructuredRecommendationCriteria(String weather) async {
    try {
      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY') {
        return '{"seasons": ["summer"], "colors": ["white", "light blue", "beige"]}'; // Fallback
      }

      final prompt = '''
You are a professional fashion stylist. The current weather is: $weather.
Based on this weather, return a JSON object with:
- "seasons": array of appropriate clothing seasons. Allowed values: summer, winter, fall, spring.
- "colors": array of 3-5 clothing color keywords that are appropriate for this weather.

Example for hot sunny day: {"seasons": ["summer", "spring"], "colors": ["white", "light blue", "beige", "yellow"]}
Example for cold rainy day: {"seasons": ["winter", "fall"], "colors": ["gray", "black", "navy", "dark green"]}

Return ONLY valid JSON without any markdown formatting.
      ''';

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      final result = response.text?.trim() ?? '{"seasons": ["summer"], "colors": ["white", "blue"]}';
      
      ErrorLogger.log(
        'AI Recommendation Criteria Request:\nPrompt: $prompt\nResponse: $result',
        severity: LogSeverity.info,
        context: 'GeminiService.recommendationCriteria',
      );
      
      return result;
    } catch (e) {
      print('Error getting structured recommendation: $e');
      return null;
    }
  }

  /// Get specific outfit recommendation based on weather and available wardrobe items
  Future<String?> getOutfitRecommendation(String weather, List<ClothingItem> wardrobe) async {
    try {
      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY' || wardrobe.isEmpty) {
        // Fallback or empty wardrobe
        return null; 
      }

      // 1. Create minimized wardrobe representation to avoid hitting token limits
      final conciseWardrobe = wardrobe.map((item) {
        return {
          "id": item.id,
          "type": item.type.name,
          "color": item.color,
          "seasons": item.seasons.map((s) => s.toString().split('.').last).toList()
        };
      }).toList();

      final wardrobeJson = jsonEncode(conciseWardrobe);

      final prompt = '''
You are a professional fashion stylist. The current weather is: $weather.
The user has the following clothing items available in their wardrobe:
$wardrobeJson

Your task is to select a cohesive outfit from ONLY these provided items that is perfect for the weather.
Choose at most 1 item from each necessary category (e.g., 1 Top, 1 Bottom, 1 Outerwear if it's cold or rainy, 1 pair of Shoes).
DO NOT invent items. You must ONLY use the exact IDs provided in the array.

Return a JSON object containing:
- "advice": A personalized, encouraging paragraph explaining why this exact outfit is a great choice for the weather. (2-3 sentences).
- "item_ids": An array containing exactly the string "id" of the items you selected to form the outfit.

Example Output:
{
  "advice": "You clearly love the timeless appeal of black tops! For 21°C and hazy weather, opt for your black cotton t-shirt to stay comfortable. Pair it with your light blue jeans to balance the look and feel fresh all day.",
  "item_ids": ["c1xxxx", "c2xxxx", "shxxxx"]
}

Return ONLY valid JSON without any markdown block formatting (no ` ```json ` tags, just the raw JSON text).
      ''';

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String result = response.text?.trim() ?? '';
      
      // Clean up markdown block if the model included it despite instructions
      if (result.startsWith('```json')) {
        result = result.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (result.startsWith('```')) {
         result = result.replaceAll('```', '').trim();
      }

      ErrorLogger.log(
        'AI Specific Outfit Request:\\nWeather: $weather\\nResponse: $result',
        severity: LogSeverity.info,
        context: 'GeminiService.getOutfitRecommendation',
      );
      
      return result;
    } catch (e) {
      print('Error getting outfit recommendation: $e');
      return null;
    }
  }

  /// Get multiple styling recommendations based on a specific vibe/event and the user's wardrobe
  Future<String?> getStyleRecommendations(String contextStr, List<ClothingItem> wardrobe) async {
    try {
      if (_textApiKey == 'PLACEHOLDER_GEMINI_KEY' || wardrobe.isEmpty) {
        return null; 
      }

      final conciseWardrobe = wardrobe.map((item) {
        return {
          "id": item.id,
          "type": item.type.name,
          "color": item.color,
          "seasons": item.seasons.map((s) => s.toString().split('.').last).toList()
        };
      }).toList();

      final wardrobeJson = jsonEncode(conciseWardrobe);

      final prompt = '''
You are a professional fashion stylist. The context for the styling session is: "$contextStr".
The user has the following clothing items available in their wardrobe:
$wardrobeJson

Your task is to create up to 3 distinct, cohesive outfit recommendations from ONLY these provided items that perfectly match the context (weather, vibe, and/or event).
For each outfit, choose at most 1 item from each necessary category (e.g., 1 Top, 1 Bottom, 1 Outerwear if needed, 1 pair of Shoes).
DO NOT invent items. You must ONLY use the exact IDs provided in the array.

Return a JSON array of objects, where each object has:
- "name": A catchy, aesthetic name for the outfit.
- "advice": A short snippet (max 2 sentences) explaining why this outfit is a great choice.
- "item_ids": An array containing exactly the string "id" of the items you selected.

Return ONLY valid JSON without any markdown block formatting (no ` ```json ` tags).
      ''';

      final content = [Content.text(prompt)];
      final response = await _textModel.generateContent(content);
      String result = response.text?.trim() ?? '';
      
      if (result.startsWith('```json')) {
        result = result.replaceAll('```json', '').replaceAll('```', '').trim();
      } else if (result.startsWith('```')) {
         result = result.replaceAll('```', '').trim();
      }

      ErrorLogger.log(
        'AI Style Recommendations Request:\nContext: $contextStr\nResponse: $result',
        severity: LogSeverity.info,
        context: 'GeminiService.getStyleRecommendations',
      );
      
      return result;
    } catch (e) {
      print('Error getting style recommendations: $e');
      return null;
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

      final promptText = prompt.replaceFirst('{weather}', weather).replaceFirst('{items}', itemDescriptions);
      final content = [Content.text(promptText)];
      final response = await _textModel.generateContent(content);
      final result = response.text ?? "Looks great!";
      
      ErrorLogger.log(
        'AI Styling Advice Request:\nPrompt: $promptText\nResponse: $result',
        severity: LogSeverity.info,
        context: 'GeminiService.stylingAdvice',
      );
      
      return result;
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
