class UserModel {
  final String uid;
  final String email;
  final String? username;
  final int? age;
  final String? phoneNumber;
  final String? imageUrl;
  final String plan;
  final int coins;
  final int puzzleScore;
  final int TotaleScore ;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.age,
    this.phoneNumber,
    this.imageUrl,
    required this.plan,
    required this.coins,
    required this.puzzleScore,
    required this.TotaleScore ,
    required this.createdAt,
  });

  // Create a copy of the user model with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    int? age,
    String? phoneNumber,
    String? imageUrl,
    String? plan,
    int? coins,
    int? puzzleScore,
    int? TotaleScore ,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      plan: plan ?? this.plan,
      coins: coins ?? this.coins,
      puzzleScore: puzzleScore ?? this.puzzleScore,
      TotaleScore: TotaleScore ?? this.TotaleScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert user model to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'age': age,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'plan': plan,
      'coins': coins,
      'puzzleScore': puzzleScore,
      'TotaleScore' :TotaleScore ,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a user model from a Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      age: map['age'],
      phoneNumber: map['phoneNumber'],
      imageUrl: map['imageUrl'],
      plan: map['plan'] ?? 'Basic',
      coins: map['coins'] ?? 0,
      TotaleScore: map['TotaleScore'] ?? 200,
      puzzleScore: map['puzzleScore'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
