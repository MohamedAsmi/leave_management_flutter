import 'package:hive/hive.dart';

part 'duty_type_model.g.dart';

@HiveType(typeId: 3)
class DutyType extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? type;

  @HiveField(3)
  final double? lat;

  @HiveField(4)
  final double? long;

  DutyType({
    required this.id,
    required this.name,
    this.type,
    this.lat,
    this.long,
  });

  factory DutyType.fromJson(Map<String, dynamic> json) {
    return DutyType(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      lat: json['lang'] != null ? double.tryParse(json['lang'].toString()) : null,
      long: json['long'] != null ? double.tryParse(json['long'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'lang': lat, // Backend uses 'lang'
      'long': long,
    };
  }
}
