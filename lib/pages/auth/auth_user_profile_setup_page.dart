import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:chinoshop/pages/main/navigation_page.dart';

class UserProfileSetupPage extends StatefulWidget {
  const UserProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<UserProfileSetupPage> createState() => _UserProfileSetupPageState();
}

class _UserProfileSetupPageState extends State<UserProfileSetupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  Future<void> _registerProfile() async {
    final user = _auth.currentUser;
    final username = _usernameController.text.trim();

    if (user == null || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // FirebaseAuthのdisplayNameを「登録済み」に設定
      await user.updateDisplayName('登録済み');
      await user.reload();

      // Firestoreにユーザー情報を保存
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavigationPage()),
      );
    } catch (e) {
      debugPrint('プロフィール登録エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録に失敗しました')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelRegistration() async {
    await _auth.currentUser?.delete(); // FirebaseAuthから削除
    await GoogleSignIn().signOut();
    Navigator.of(context).pop(); // 前の画面（ログイン画面）へ戻る
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名（名字を入力してください）',
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _cancelRegistration,
                        child: const Text('キャンセル'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _registerProfile,
                        child: const Text('登録'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
