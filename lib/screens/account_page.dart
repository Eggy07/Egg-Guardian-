import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class AccountPage extends StatefulWidget {
  final String userId; // Document ID in Firestore

  const AccountPage({super.key, required this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _image; // Mobile image
  Uint8List? _webImage; // Web image
  bool isLoading = true;
  bool _showPassword = false;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? _profileImageUrl;

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('user');

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// ---- FETCH USER DATA ----
  Future<void> _fetchUserData() async {
    try {
      final docSnapshot = await usersCollection.doc(widget.userId).get();

      if (!docSnapshot.exists) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      setState(() {
        usernameController.text = data['full_name'] ?? '';
        emailController.text = data['email'] ?? '';
        _profileImageUrl = data['profile_image_url'];
        isLoading = false;
      });

      debugPrint('User data fetched: ${data['full_name']}');
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// ---- PICK IMAGE ----
  Future<void> _pickImage() async {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        // For Android 13+ use READ_MEDIA_IMAGES
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access gallery denied'),
            ),
          );
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access gallery denied'),
            ),
          );
          return;
        }
      }
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _image = null;
        });
        debugPrint('Web image selected: ${bytes.length} bytes');
      } else {
        setState(() {
          _image = File(pickedFile.path);
          _webImage = null;
        });
        debugPrint('Mobile image selected: ${pickedFile.path}');
      }
    }
  }

  /// ---- UPDATE USER DATA ----
  Future<void> _updateUserData() async {
    setState(() => isLoading = true);

    try {
      String? imageUrl = _profileImageUrl;

      if ((_image != null && !kIsWeb) || (_webImage != null && kIsWeb)) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${widget.userId}.jpg',
        );

        UploadTask uploadTask;
        final metadata = SettableMetadata(contentType: 'image/jpeg');

        if (kIsWeb && _webImage != null) {
          uploadTask = storageRef.putData(_webImage!, metadata);
        } else if (!kIsWeb && _image != null) {
          uploadTask = storageRef.putFile(_image!, metadata);
        } else {
          throw Exception('No image data to upload');
        }

        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
        debugPrint('Image uploaded: $imageUrl');
      }

      await usersCollection.doc(widget.userId).update({
        'full_name': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'profile_image_url': imageUrl,
      });

      setState(() {
        if (imageUrl != null) {
          _profileImageUrl =
              '$imageUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
        }
        _image = null;
        _webImage = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e, st) {
      setState(() => isLoading = false);
      debugPrint('Error updating profile: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// ---- BUILD UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: const Color(0xFFFFC400),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  /// ---- PROFILE IMAGE ----
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFFFFF3CD),
                        foregroundImage: _image != null
                            ? FileImage(_image!)
                            : (_webImage != null
                                  ? MemoryImage(_webImage!)
                                  : (_profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : null)),
                        child:
                            (_image == null &&
                                _webImage == null &&
                                _profileImageUrl == null)
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

                  /// ---- USERNAME ----
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

                  /// ---- EMAIL ----
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

                  /// ---- PASSWORD ----
                  TextField(
                    controller: passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password (unchanged)',
                      filled: true,
                      fillColor: const Color(0xFFFFF3CD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ---- SAVE BUTTON ----
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
