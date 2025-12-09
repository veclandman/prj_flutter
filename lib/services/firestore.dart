import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prj_flutter/models/Password.dart';
import 'package:prj_flutter/models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EncryptionHelper.dart';

class FirestoreService {
  final CollectionReference passwords =
      FirebaseFirestore.instance.collection('passwords');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  //* retreiving all the passwords created by the user logged in
  Stream<QuerySnapshot> getPasswords() async* {
    try {
      final userSnapshot = await getLoggedInUser();
      if (userSnapshot.docs.isNotEmpty) {
        String userId = userSnapshot.docs.first.id;
        yield* passwords.where('user', isEqualTo: userId).snapshots();
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print("Error in getPasswords stream: $e");
    }
  }

//* creating the password (name , pass and username ) after checking that the user is logged in
  Future<String> createPassword(
      String name, String username, String password) async {
    try {
      final user = await getLoggedInUser();
      if (user.docs.isNotEmpty || name.isNotEmpty || username.isNotEmpty || password.isNotEmpty) {
        String userId = user.docs.first.id;
        String encryptedPassword = EncryptionHelper.encrypt(password);
        await passwords.add(Password(
                name: name,
                username: username,
                password: encryptedPassword,
                user: userId)
            .toJson());
        return "Password Added";
      } else {
        return "User not found";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

//* updating the password doc that has the docID as an ID after checking that the user exists
  Future<String> updatePassword(
      String docID, String name, String username, String password) async {
    try {
      final user = await getLoggedInUser();
      if (user.docs.isNotEmpty) {
        String userId = user.docs.first.id;
        String encryptedPassword = EncryptionHelper.encrypt(password);

        await passwords.doc(docID).update(Password(
                name: name,
                username: username,
                password: encryptedPassword,
                user: userId)
            .toJson());
        return "Account Updated";
      } else {
        return "User not found";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

//* deleting the password with the DocID
  Future<String> deletePassword(String docID) async {
    try {
      await passwords.doc(docID).delete();
      return "Account Deleted";
    } catch (e) {
      return "Error: $e";
    }
  }

//* getting the logged in user from the database
  Future<QuerySnapshot> getLoggedInUser() async {
    String? userId = await _getUserId();
    if (userId != null) {
      return await users.where(FieldPath.documentId, isEqualTo: userId).get();
    } else {
      throw Exception('User ID not found');
    }
  }

//* getting the name of the logged in user
  Future<String> getLoggedInName() async {
    final userSnapshot = await getLoggedInUser();
    String userId = userSnapshot.docs.first.id;
    final snapshot =
        await users.where(FieldPath.documentId, isEqualTo: userId).get();
    return snapshot.docs.first.get('name');
  }

//* getting the user by phone
  Future<QuerySnapshot> getUserByPhone(String telephone, String code) {
    return users
        .where('telephone', isEqualTo: telephone)
        .where('code', isEqualTo: code)
        .get();
  }

//! helper methode to get the password by its id to fill the update form
  Future<QuerySnapshot> getPasswordById(String? docID) {
    return passwords.where(FieldPath.documentId, isEqualTo: docID).get();
  }

//* getting the user by email
  Future<QuerySnapshot> getUserByEmail(String email, String code) {
    return users
        .where('email', isEqualTo: email)
        .where('code', isEqualTo: code)
        .get();
  }

//! registering methode that checks the existence of the user before adding it to the database
  Future<String> registerUser(
      String name, String email, String telephone, String code) async {
    if (name.isEmpty || email.isEmpty || telephone.isEmpty || code.isEmpty) {
      return "all fields are required";
    }

    final phoneUser = await getUserByPhone(telephone, code);
    final emailUser = await getUserByEmail(email, code);

    if (emailUser.docs.isNotEmpty || phoneUser.docs.isNotEmpty) {
      return "Email or Phone number already registered";
    } 

    await users.add(
          User(name: name, email: email, telephone: telephone, code: code)
              .toJson());
    return "Success";
    
  }

//* login function that return true if the user is found and false if the user none existent
  Future<bool> loginUser(String emailOrPhone, String code) async {
    try {
      
      final emailUser = await getUserByEmail(emailOrPhone, code);
      final phoneUser = await getUserByPhone(emailOrPhone, code);

      if (emailUser.docs.isNotEmpty) {
        await _saveUserId(emailUser.docs.first.id);
        return true;
      } else if (phoneUser.docs.isNotEmpty) {
        await _saveUserId(phoneUser.docs.first.id);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

//! helper methode that saves the userid of the loggedin user in the sharedpreference of the application
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

//! helper methode that gets the userid of the loggedin user from the sharedpreference of the application
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

//? logout method that deletes the userid from the sharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}
