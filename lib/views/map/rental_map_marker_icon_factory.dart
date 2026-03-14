import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RentalMapMarkerIconFactory {
  static const double markerSize = 78;
  static const String fallbackCacheKey = '__fallback_marker__';
  static const Color _accentColor = Color(0xFF16BCE6);
  static const int _canvasWidth = 180;
  static const int _canvasHeight = 228;
  static const double _pinCircleRadius = 54;
  static const double _ringRadius = 47;
  static const double _contentRadius = 40;
  static const double _pointerHeight = 58;
  static const double _pointerHalfWidth = 20;

  final Map<String, BitmapDescriptor> _iconCache = <String, BitmapDescriptor>{};
  final Map<String, Future<BitmapDescriptor>> _inFlight =
      <String, Future<BitmapDescriptor>>{};

  String cacheKeyForImage(String imageUrl) {
    final normalizedUrl = imageUrl.trim();
    return normalizedUrl.isEmpty ? fallbackCacheKey : normalizedUrl;
  }

  BitmapDescriptor? cachedDescriptor(String cacheKey) => _iconCache[cacheKey];

  Future<BitmapDescriptor> fallbackDescriptor() => loadDescriptor('');

  Future<BitmapDescriptor> loadDescriptor(String imageUrl) {
    final cacheKey = cacheKeyForImage(imageUrl);
    final cachedDescriptor = _iconCache[cacheKey];
    if (cachedDescriptor != null) {
      return Future<BitmapDescriptor>.value(cachedDescriptor);
    }

    final inFlightDescriptor = _inFlight[cacheKey];
    if (inFlightDescriptor != null) {
      return inFlightDescriptor;
    }

    final future = _createDescriptor(
      imageUrl: imageUrl.trim(),
      cacheKey: cacheKey,
    );
    _inFlight[cacheKey] = future;
    return future;
  }

  Future<BitmapDescriptor> _createDescriptor({
    required String imageUrl,
    required String cacheKey,
  }) async {
    try {
      final descriptor = imageUrl.isEmpty
          ? await _buildFallbackDescriptor()
          : await _buildImageDescriptor(imageUrl);
      _iconCache[cacheKey] = descriptor;
      return descriptor;
    } catch (_) {
      final fallbackDescriptor = await _buildFallbackDescriptor();
      _iconCache[cacheKey] = fallbackDescriptor;
      return fallbackDescriptor;
    } finally {
      _inFlight.remove(cacheKey);
    }
  }

  Future<BitmapDescriptor> _buildImageDescriptor(String imageUrl) async {
    final image = await _loadImage(imageUrl);
    final markerBytes = await _drawMarkerBytes(image: image);
    return BitmapDescriptor.bytes(
      markerBytes,
      width: markerSize,
      height: markerSize,
    );
  }

  Future<BitmapDescriptor> _buildFallbackDescriptor() async {
    final cachedFallback = _iconCache[fallbackCacheKey];
    if (cachedFallback != null) {
      return cachedFallback;
    }

    final markerBytes = await _drawMarkerBytes();
    final descriptor = BitmapDescriptor.bytes(
      markerBytes,
      width: markerSize,
      height: markerSize,
    );
    _iconCache[fallbackCacheKey] = descriptor;
    return descriptor;
  }

  Future<ui.Image> _loadImage(String imageUrl) {
    final completer = Completer<ui.Image>();
    final imageProvider = CachedNetworkImageProvider(
      imageUrl,
      maxWidth: 256,
      maxHeight: 256,
    );
    final imageStream = imageProvider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(imageInfo.image);
        }
        imageStream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        imageStream.removeListener(listener);
      },
    );

    imageStream.addListener(listener);
    return completer.future;
  }

  Future<Uint8List> _drawMarkerBytes({ui.Image? image}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(_canvasWidth / 2, _pinCircleRadius + 12);
    final pointerTip = Offset(center.dx, _canvasHeight - 16);

    final markerPath = Path()
      ..moveTo(center.dx, pointerTip.dy)
      ..quadraticBezierTo(
        center.dx - (_pointerHalfWidth * 0.72),
        center.dy + (_pointerHeight * 0.52),
        center.dx - (_pinCircleRadius * 0.76),
        center.dy + (_pinCircleRadius * 0.62),
      )
      ..arcToPoint(
        Offset(
          center.dx + (_pinCircleRadius * 0.76),
          center.dy + (_pinCircleRadius * 0.62),
        ),
        radius: const Radius.circular(_pinCircleRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(
        center.dx + (_pointerHalfWidth * 0.72),
        center.dy + (_pointerHeight * 0.52),
        center.dx,
        pointerTip.dy,
      )
      ..close();
    canvas.drawShadow(markerPath, const Color(0x55000000), 16, true);

    canvas.drawPath(markerPath, Paint()..color = _accentColor);
    canvas.drawCircle(center, _ringRadius, Paint()..color = Colors.white);

    final contentRect = Rect.fromCircle(center: center, radius: _contentRadius);
    final contentPath = Path()..addOval(contentRect);

    canvas.save();
    canvas.clipPath(contentPath);
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: contentRect,
        image: image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
    } else {
      final fallbackPaint = Paint()
        ..shader = ui.Gradient.linear(
          contentRect.topLeft,
          contentRect.bottomRight,
          const <Color>[Color(0xFFF4F7FA), Color(0xFFDCE6EE)],
        );
      canvas.drawRect(contentRect, fallbackPaint);
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      _contentRadius,
      Paint()
        ..color = const Color(0x14000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    if (image == null) {
      _paintFallbackGlyph(canvas, center);
    }

    final markerImage = await recorder.endRecording().toImage(
      _canvasWidth,
      _canvasHeight,
    );
    final byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw StateError('Failed to encode map marker bitmap.');
    }

    return byteData.buffer.asUint8List();
  }

  void _paintFallbackGlyph(Canvas canvas, Offset center) {
    final icon = Icons.image_outlined;
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 38,
          color: const Color(0xFF8A97A6),
          fontFamily: icon.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - (painter.width / 2), center.dy - (painter.height / 2)),
    );
  }
}
