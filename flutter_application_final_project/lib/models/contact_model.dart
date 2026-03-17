class Contact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool emergencyNotificationsEnabled;

  const Contact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.emergencyNotificationsEnabled,
  });

  Contact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phoneNumber,
    bool? emergencyNotificationsEnabled,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyNotificationsEnabled:
          emergencyNotificationsEnabled ?? this.emergencyNotificationsEnabled,
    );
  }
}
