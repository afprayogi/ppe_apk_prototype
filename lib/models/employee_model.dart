class EmployeeModel {
  final String id;
  final String name;
  final String nia;
  final String address;
  final String shift;
  final List<String> requiredPpe;
  final String? avatarUrl;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.nia,
    required this.address,
    required this.shift,
    required this.requiredPpe,
    this.avatarUrl,
  });

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? nia,
    String? address,
    String? shift,
    List<String>? requiredPpe,
    String? avatarUrl,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nia: nia ?? this.nia,
      address: address ?? this.address,
      shift: shift ?? this.shift,
      requiredPpe: requiredPpe ?? this.requiredPpe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'nia': nia,
        'address': address,
        'shift': shift,
        'requiredPpe': requiredPpe,
        'avatarUrl': avatarUrl,
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map) => EmployeeModel(
        id: map['id'] as String,
        name: map['name'] as String,
        nia: map['nia'] as String,
        address: map['address'] as String,
        shift: map['shift'] as String,
        requiredPpe: List<String>.from(map['requiredPpe'] as List),
        avatarUrl: map['avatarUrl'] as String?,
      );
}
