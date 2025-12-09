class User {
  final String name;
  final String email;
  final String telephone;
  final String code;

  User({
    required this.name,
    required this.email,
    required this.telephone,
    required this.code,
  });

  //* Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      telephone: json['telephone'],
      code: json['code'],
    );
  }

  //* Convert User to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'telephone': telephone,
        'code': code,
      };
}
