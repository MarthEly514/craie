import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

import '../../features/resources/data/models/resource_model.dart';

typedef LatLng = ({double lat, double lng});

/// Extracts coordinates from a pasted Google Maps link (or a plain "lat, lng").
/// Returns null for links without coordinates (e.g. short maps.app.goo.gl links).
LatLng? parseCoordinates(String? text) {
  if (text == null || text.isEmpty) return null;
  const n = r'(-?\d{1,3}\.\d+)';
  final patterns = [
    RegExp('@$n,$n'),
    RegExp('!3d$n!4d$n'),
    RegExp('[?&](?:q|query|ll|center)=$n(?:,|%2C)$n'),
    RegExp('^\\s*$n\\s*,\\s*$n\\s*\$'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(text);
    if (m != null) {
      final lat = double.parse(m.group(1)!);
      final lng = double.parse(m.group(2)!);
      if (lat.abs() <= 90 && lng.abs() <= 180) return (lat: lat, lng: lng);
    }
  }
  return null;
}

/// Link to open for a room: its Maps link, or a search on its name/location.
String mapsLinkFor(ResourceModel room) {
  final url = room.mapsUrl;
  if (url != null && url.isNotEmpty) {
    final withScheme = url.startsWith('http') ? url : 'https://$url';
    final c = parseCoordinates(url);
    // A bare "lat, lng" is not a URL: turn it into one.
    return c != null && !url.startsWith('http') && !url.contains('.')
        ? 'https://www.google.com/maps/search/?api=1&query=${c.lat},${c.lng}'
        : withScheme;
  }
  final query = Uri.encodeComponent('${room.name} ${room.zone} ${room.location}');
  return 'https://www.google.com/maps/search/?api=1&query=$query';
}

Future<bool> openMaps(ResourceModel room) =>
    launchUrl(Uri.parse(mapsLinkFor(room)), mode: LaunchMode.externalApplication);

/// Slippy-map tile coordinates (fractional) of a point at [zoom].
({double x, double y}) tileOf(LatLng p, int zoom) {
  final n = math.pow(2, zoom).toDouble();
  final latRad = p.lat * math.pi / 180;
  return (
    x: (p.lng + 180) / 360 * n,
    y: (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n,
  );
}
