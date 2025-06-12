import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_user_profile_setup_page.dart';
import 'package:portfolio_chinoshop/pages/main/navigation_page.dart';

class FirebaseAuthCheckPage extends StatefulWidget {
  const FirebaseAuthCheckPage({Key? key}) : super(key: key);

  @override
  State<FirebaseAuthCheckPage> createState() => _FirebaseAuthCheckPageState();
}

class _FirebaseAuthCheckPageState extends State<FirebaseAuthCheckPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  void _checkProfileCompletion() async {
    final user = _auth.currentUser;

    if (user == null) {
      // 未ログインの場合
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    await user.reload(); // displayNameが最新であることを保証するためにリロード

    // displayNameが登録済みかどうかを確認
    if (user.displayName == '登録済み') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => UserProfileSetupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
