class UserProfile {
  final int id;
  final String nickname;
  final String? email;

  UserProfile(
      {
        required this.id,
        required this.nickname,
        this.email
      }
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      nickname: json['nickname'],
      email: json['email'],
    );
  }
}