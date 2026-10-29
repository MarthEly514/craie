import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/maps.dart';
import '../../features/resources/data/models/resource_model.dart';

/// Map of a room built from OpenStreetMap tiles around the coordinates found
/// in its Maps link. Tapping opens the link in the external Maps app / browser.
/// Without coordinates (or offline) it falls back to a static picture.
class MapPreview extends StatelessWidget {
  final ResourceModel room;

  const MapPreview({super.key, required this.room});

  static const _zoom = 16;
  static const _tile = 256.0;
  static const _height = 170.0;

  @override
  Widget build(BuildContext context) {
    final coords = parseCoordinates(room.mapsUrl);
    return GestureDetector(
      onTap: () async {
        final ok = await openMaps(room);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir la carte')),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              coords == null ? _fallback() : _tiles(coords),
              if (coords != null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Icon(Icons.location_on, size: 40, color: Colors.red),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 14),
                      SizedBox(width: 6),
                      Text('Ouvrir dans Maps',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Image.asset('assets/images/map_placeholder.png', fit: BoxFit.cover);

  Widget _tiles(LatLng c) {
    final t = tileOf(c, _zoom);
    final max = math.pow(2, _zoom).toInt();
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      // Pixel offset of the point inside the tile grid, centred in the box.
      final originX = w / 2 - t.x * _tile;
      final originY = _height / 2 - t.y * _tile;
      final firstX = ((t.x * _tile - w / 2) / _tile).floor();
      final lastX = ((t.x * _tile + w / 2) / _tile).floor();
      final firstY = ((t.y * _tile - _height / 2) / _tile).floor();
      final lastY = ((t.y * _tile + _height / 2) / _tile).floor();
      return Container(
        color: AppColors.surface,
        child: Stack(
          children: [
            for (var x = firstX; x <= lastX; x++)
              for (var y = firstY; y <= lastY; y++)
                if (y >= 0 && y < max)
                  Positioned(
                    left: originX + x * _tile,
                    top: originY + y * _tile,
                    width: _tile,
                    height: _tile,
                    child: Image.network(
                      'https://tile.openstreetmap.org/$_zoom/${x % max}/$y.png',
                      headers: const {'User-Agent': 'craie-app/1.0'},
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
          ],
        ),
      );
    });
  }
}
