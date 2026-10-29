enum ResourceType { room, equipment }

extension ResourceTypeJson on ResourceType {
  String get json => switch (this) {
        ResourceType.room => 'room',
        ResourceType.equipment => 'equipment',
      };

  static ResourceType fromJson(String value) => switch (value) {
        'room' => ResourceType.room,
        'equipment' => ResourceType.equipment,
        _ => throw FormatException('Unknown resource type: $value'),
      };
}

class ResourceModel {
  final String id;
  final String name;
  final ResourceType type;

  /// Currently reserved. Sent by the API in list/detail responses; never sent back.
  final bool isTaken;

  // Rooms
  final String zone;
  final String location;
  final String? mapsUrl;
  final List<String> amenities;

  // Equipment
  final String category;
  final String description;
  final bool isBroken;

  const ResourceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isTaken = false,
    this.zone = '',
    this.location = '',
    this.mapsUrl,
    this.amenities = const [],
    this.category = '',
    this.description = '',
    this.isBroken = false,
  });

  bool get isRoom => type == ResourceType.room;

  String get subtitle => isRoom ? '$zone ($location)' : description;

  String get filterKey => isRoom ? zone : category;

  factory ResourceModel.fromJson(Map<String, dynamic> json) => ResourceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ResourceTypeJson.fromJson(json['type'] as String),
        isTaken: json['isTaken'] as bool? ?? false,
        zone: json['zone'] as String? ?? '',
        location: json['location'] as String? ?? '',
        mapsUrl: json['mapsUrl'] as String?,
        amenities: (json['amenities'] as List?)?.cast<String>() ?? const [],
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isBroken: json['isBroken'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.json,
        if (isRoom) ...{
          'zone': zone,
          'location': location,
          if (mapsUrl != null) 'mapsUrl': mapsUrl,
          'amenities': amenities,
        } else ...{
          'category': category,
          'description': description,
          'isBroken': isBroken,
        },
      };

}
