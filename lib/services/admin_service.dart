import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static const List<String> adminIds = [
    'NdQLsCCLSNV3Yv7fLlo6dVmNcxu1',
    // Add more admin IDs here as needed
  ];

  static bool isAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return adminIds.contains(user.uid);
  }

  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
} 