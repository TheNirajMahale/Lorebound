/// Domain model representing the authenticated Lorekeeper user.
class User {
  final int id;
  final String email;
  final String authProvider; // 'LOCAL' or 'GOOGLE'
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.authProvider,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      authProvider: json['authProvider'] as String? ?? 'LOCAL',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'authProvider': authProvider,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          authProvider == other.authProvider;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ authProvider.hashCode;
}
