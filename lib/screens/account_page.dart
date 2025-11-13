import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountPage extends StatefulWidget {
  final String userId; // Firestore "user_id" field
  const AccountPage({super.key, required this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _image;
  final picker = ImagePicker();
  bool isLoading = true;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  String? _currentDocId; // Store actual Firestore document ID
  String? _profileImageUrl; // Store Firestore image URL

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      final querySnapshot = await usersCollection
          .where('user_id', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      // Get document and data
      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _currentDocId = doc.id; // store actual doc ID for updates
        usernameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        passwordController.text = '';
        _profileImageUrl = data['profile_image_url'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user: $e')));
    }
  }

  /// Update user data in Firestore + upload image to Firebase Storage
  Future<void> _updateUserData() async {
    if (_currentDocId == null) return;

    setState(() => isLoading = true);

    try {
      String? imageUrl = _profileImageUrl;

      // Upload new image if picked
      if (_image != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}',
        );
        final uploadTask = await storageRef.putFile(_image!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final updateData = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        if (imageUrl != null) 'profile_image_url': imageUrl,
      };

      await usersCollection.doc(_currentDocId).update(updateData);

      if (!mounted) return;
      setState(() {
        _profileImageUrl = imageUrl;
        isLoading = false;
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC400),
        title: const Text('My Account'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFFFFF3CD),
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null)
                                  as ImageProvider<Object>?,
                        child: (_image == null && _profileImageUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.black54,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC400),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      filled: true,
                      fillColor: const Color(0xFFFFF3CD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFFFFF3CD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password (unchanged)',
                      filled: true,
                      fillColor: const Color(0xFFFFF3CD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC400),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 80,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
