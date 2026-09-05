import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Encode a live [CameraImage] to JPEG bytes (no shutter / takePicture).
Uint8List? encodeCameraImageJpeg(CameraImage image, {int quality = 70}) {
  try {
    final converted = switch (image.format.group) {
      ImageFormatGroup.bgra8888 => _bgra8888(image),
      ImageFormatGroup.yuv420 => _yuv420(image),
      ImageFormatGroup.nv21 => _yuv420(image),
      // iOS can report unknown while still delivering BGRA (4 bpp, padded rows).
      _ => (image.planes.isNotEmpty &&
              (image.planes.first.bytesPerPixel ?? 4) >= 4)
          ? _bgra8888(image)
          : _yuv420(image),
    };
    if (converted == null) return null;
    return Uint8List.fromList(img.encodeJpg(converted, quality: quality));
  } catch (e) {
    debugPrint('[DocReader] frame encode=$e');
    return null;
  }
}

img.Image? _bgra8888(CameraImage image) {
  final plane = image.planes.first;
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: plane.bytes.buffer,
    bytesOffset: plane.bytes.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
    rowStride: plane.bytesPerRow,
  );
}

img.Image? _yuv420(CameraImage image) {
  final width = image.width;
  final height = image.height;
  if (image.planes.length < 2) return null;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes.length > 2 ? image.planes[2] : uPlane;
  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;
  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final out = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    final yRow = y * yRowStride;
    final uvRow = (y >> 1) * uvRowStride;
    for (var x = 0; x < width; x++) {
      final yp = yBytes[yRow + x] & 0xff;
      final uvIndex = uvRow + (x >> 1) * uvPixelStride;
      final up = uvIndex < uBytes.length ? (uBytes[uvIndex] & 0xff) : 128;
      final vp = uvIndex < vBytes.length ? (vBytes[uvIndex] & 0xff) : 128;
      final r = (yp + 1.370705 * (vp - 128)).round().clamp(0, 255);
      final g =
          (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round().clamp(0, 255);
      final b = (yp + 1.732446 * (up - 128)).round().clamp(0, 255);
      out.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return out;
}

/// Write a JPEG still from a preview frame into a temp file.
Future<String?> writeCameraFrameJpeg(CameraImage image, {int quality = 70}) async {
  final jpeg = encodeCameraImageJpeg(image, quality: quality);
  if (jpeg == null || jpeg.isEmpty) return null;
  final file = File(
    '${Directory.systemTemp.path}/dr_frame_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(jpeg, flush: false);
  return file.path;
}
