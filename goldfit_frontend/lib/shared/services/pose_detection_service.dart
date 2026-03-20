import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseAlignmentResult {
  final Rect topRect; // Bounding box for tops (shoulders to hips)
  final Rect bottomRect; // Bounding box for bottoms (hips to ankles)
  final double scale;
  final double imageWidth;
  final double imageHeight;

  PoseAlignmentResult({
    required this.topRect,
    required this.bottomRect,
    required this.scale,
    required this.imageWidth,
    required this.imageHeight,
  });
}

class PoseDetectionService {
  final PoseDetector _poseDetector;

  PoseDetectionService()
      : _poseDetector = PoseDetector(options: PoseDetectorOptions());

  void dispose() {
    _poseDetector.close();
  }

  /// Processes an image and returns alignment rectangles for tops and bottoms
  Future<PoseAlignmentResult?> analyzeImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final inputImage = InputImage.fromFile(file);
    final List<Pose> poses = await _poseDetector.processImage(inputImage);

    if (poses.isEmpty) return null;

    final pose = poses.first;
    
    // Get key landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null || rightShoulder == null || leftHip == null || rightHip == null) {
      return null; // Not enough data for tops
    }

    // Calculate Top Rect (Shoulders to Hips)
    final shoulderWidth = (rightShoulder.x - leftShoulder.x).abs();
    final topWidth = shoulderWidth * 1.5; // Add padding
    final topHeight = (leftHip.y - leftShoulder.y).abs() * 1.2;
    
    final topCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final topCenterY = (leftShoulder.y + leftHip.y) / 2;

    final topRect = Rect.fromCenter(
      center: Offset(topCenterX, topCenterY),
      width: topWidth,
      height: topHeight,
    );

    // Calculate Bottom Rect (Hips to Ankles)
    Rect bottomRect = Rect.zero;
    if (leftAnkle != null && rightAnkle != null) {
      final hipWidth = (rightHip.x - leftHip.x).abs();
      final bottomWidth = hipWidth * 1.5;
      final bottomHeight = (leftAnkle.y - leftHip.y).abs() * 1.1;
      
      final bottomCenterX = (leftHip.x + rightHip.x) / 2;
      final bottomCenterY = (leftHip.y + leftAnkle.y) / 2;

      bottomRect = Rect.fromCenter(
        center: Offset(bottomCenterX, bottomCenterY),
        width: bottomWidth,
        height: bottomHeight,
      );
    }

    // Attempt to get image dimensions
    double width = 1000;
    double height = 1000;
    try {
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      width = decodedImage.width.toDouble();
      height = decodedImage.height.toDouble();
    } catch (e) {
      print('Could not decode image size: $e');
    }

    return PoseAlignmentResult(
      topRect: topRect,
      bottomRect: bottomRect,
      scale: 1.0,
      imageWidth: width,
      imageHeight: height,
    );
  }
}
