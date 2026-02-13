class PersonModel {
  final Map<String, dynamic>? name;
  final Map<String, dynamic>? position;
  final String personcode;
  final Map<String, dynamic>? department;
  final String email;
  final String? urlimage;

  PersonModel({
    this.name,
    this.position,
    this.personcode = '',
    this.department,
    this.email = '',
    this.urlimage,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    }

    return PersonModel(
      name: asMap(json['name']),
      position: asMap(json['position']),
      personcode: (json['personcode'] ?? '').toString(),
      department: asMap(json['department']),
      email: (json['email'] ?? '').toString(),
      urlimage: json['urlimage']?.toString(),
    );
  }
}
