import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'username': username,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, username: $username)';
}
