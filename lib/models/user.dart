class User {
  final String id;
  final String lastName;
  final String firstName;
  final String email;
  final String password; // Demo only; hash in production
  final String? bankAccount;

  User({
    String? id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.password,
    this.bankAccount,
  }) : id = id ?? _uuid();

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String?,
        lastName: json['lastName'] as String,
        firstName: json['firstName'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        bankAccount: json['bankAccount'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastName': lastName,
        'firstName': firstName,
        'email': email,
        'password': password,
        'bankAccount': bankAccount,
      };
}

String _uuid() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
    '-' +
    (DateTime.now().millisecondsSinceEpoch % 1000000).toRadixString(16);
