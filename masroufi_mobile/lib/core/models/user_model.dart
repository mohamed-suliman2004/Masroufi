import 'package:flutter/material.dart';

class UserModel {
  final int? id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? token;

  const UserModel({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    final rawName = (json['name'] ?? '') as String;
    final cleanName = rawName.trim() == 'مستخدم مصروفي' ? '' : rawName.trim();
    return UserModel(
      id: json['id'] as int?,
      name: cleanName,
      phoneNumber: (json['phone_number'] ?? '') as String,
      email: json['email'] as String?,
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'token': token,
    };
  }

  String get displayName {
    final clean = name.trim();
    if (clean.isNotEmpty && clean != 'مستخدم مصروفي') {
      return clean;
    }
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim().split('@')[0];
    }
    return '';
  }

  String get initial {
    final d = displayName;
    return d.isNotEmpty ? d.characters.first : 'م';
  }
}
