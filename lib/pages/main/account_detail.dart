import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:chinoshop/pages/auth/auth_login.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();

  String? username;
  String? photoUrl;
  bool isSaving = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    setState(() {
      photoUrl = user.photoURL;
      username = doc['username'] ?? '';
      _nameController.text = username!;
    });
  }

  Future<void> _updateUsername() async {
    final trimmed = _nameController.text.trim();

    if (trimmed.isEmpty) {
      setState(() => errorText = 'ユーザー名を入力してください');
      return;
    }

    setState(() {
      isSaving = true;
      errorText = null;
    });

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'username': trimmed,
      });

      setState(() {
        username = trimmed;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザー名を更新しました')),
      );
    }
  }

  Future<void> _logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: Image.asset(
          'assets/images/SHOP_logo0.png',
          height: kToolbarHeight,
          width: kToolbarHeight,
          fit: BoxFit.contain,
        ),
        title: const Text(
          'アカウント',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/images/guest_user_icon.png') as ImageProvider,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ユーザー名',
                errorText: errorText,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isSaving ? null : _updateUsername,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト'),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
