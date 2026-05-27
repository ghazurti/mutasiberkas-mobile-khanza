class UserSession {
  final String token;
  final String username;
  final String nama;
  final String level;

  const UserSession({
    required this.token,
    required this.username,
    required this.nama,
    required this.level,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        token: json['token'] as String,
        username: json['username'] as String,
        nama: json['nama'] as String,
        level: json['level'] as String,
      );
}
