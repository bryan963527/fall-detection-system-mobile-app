class RelativeModel {
  final String? id;
  final String name;
  final int age;
  final String relationship;
  final String contact;
  final String address;
  final String? createdAt;

  RelativeModel({
    this.id,
    required this.name,
    required this.age,
    required this.relationship,
    required this.contact,
    required this.address,
    this.createdAt,
  });

  // Convert RelativeModel to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'relationship': relationship,
      'contact': contact,
      'address': address,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Create RelativeModel from JSON
  factory RelativeModel.fromJson(Map<dynamic, dynamic> json) {
    return RelativeModel(
      name: json['name'] as String? ?? 'Unknown',
      age: json['age'] as int? ?? 0,
      relationship: json['relationship'] as String? ?? 'Other',
      contact: json['contact'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  // Copy with method for updates
  RelativeModel copyWith({
    String? id,
    String? name,
    int? age,
    String? relationship,
    String? contact,
    String? address,
    String? createdAt,
  }) {
    return RelativeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      relationship: relationship ?? this.relationship,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
