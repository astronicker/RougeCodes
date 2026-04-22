import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  User? _firebaseUser;
  AppUser? _profile;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isStudent => _profile?.isUser ?? false;

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    _profileSubscription?.cancel();

    if (user == null) {
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final initialDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (initialDoc.exists) {
        final nextProfile = AppUser.fromDoc(initialDoc);
        if (!nextProfile.isArchived) {
          _profile = nextProfile;
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep the live listener as the fallback path.
    }

    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) async {
            if (!doc.exists) {
              _profile = null;
              _isLoading = false;
              notifyListeners();
              await FirebaseAuth.instance.signOut();
              return;
            }

            final nextProfile = AppUser.fromDoc(doc);
            if (nextProfile.isArchived) {
              _profile = null;
              _isLoading = false;
              notifyListeners();
              await FirebaseAuth.instance.signOut();
              return;
            }

            _profile = nextProfile;
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _profile = null;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> logout() {
    return FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
