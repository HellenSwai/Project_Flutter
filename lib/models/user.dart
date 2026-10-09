class AppUser {
  final String id;              // uuid from auth.users
  final String email;
  final String? fullName;
  final String role;            // 'admin' | 'manager' | 'salesclerk'
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.role = 'salesclerk',
    this.createdAt,
  });

  // FROM Supabase JSON → AppUser
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'salesclerk',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // AppUser → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
    };
  }

  // ------------------------------------------------------------
  // Convenience: build from Supabase Auth User
  // ------------------------------------------------------------
  factory AppUser.fromAuthUser(dynamic authUser) {
    return AppUser(
      id: authUser.id as String,
      email: authUser.email as String? ?? '',
      fullName: authUser.userMetadata?['full_name'] as String?,
      role: authUser.userMetadata?['role'] as String? ?? 'salesclerk',
      createdAt: DateTime.tryParse(authUser.createdAt ?? ''),
    );
  }

  // Role helpers

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSalesclerk => role == 'salesclerk';

  @override
  String toString() => 'AppUser($email, role: $role)';
}