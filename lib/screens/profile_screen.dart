

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:traveleasy/screens/bookingPage.dart';
import 'package:traveleasy/screens/signup_screen.dart';
import 'login_screen.dart';
import 'package:traveleasy/components/custom_app_bar.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int _selectedIndex = 2;

  final _picker = ImagePicker();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _photoUrl;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  // Initialize SharedPreferences
  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedUserData();  // Load cached data first
    _fetchUserDataFromFirestore();  // Fetch fresh data from Firestore
  }

  // Load cached data from SharedPreferences
  void _loadCachedUserData() {
    setState(() {
      _nameController.text = _prefs?.getString('name') ?? 'Your Name';
      _photoUrl = _prefs?.getString('photoUrl') ?? 'https://picsum.photos/200/300.jpg';
      _emailController.text = _currentUser?.email ?? '';
    });
  }

  // Fetch user data from Firestore and update cache
  Future<void> _fetchUserDataFromFirestore() async {
    if (_currentUser != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      // Update the cached data
      _prefs?.setString('name', userData['name'] ?? 'Your Name');
      _prefs?.setString('photoUrl', userData['photoUrl'] ?? 'https://picsum.photos/200/300.jpg');

      // Update the UI with the fresh data
      setState(() {
        _nameController.text = userData['name'] ?? 'Your Name';
        _photoUrl = userData['photoUrl'] ?? 'https://picsum.photos/200/300.jpg';
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_image == null) return;

    try {
      String fileName = 'profile_pictures/${_currentUser!.uid}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_image!);

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'photoUrl': downloadUrl});

      // Cache the new photo URL
      _prefs?.setString('photoUrl', downloadUrl);

      setState(() {
        _photoUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture uploaded successfully!')),
      );
    } catch (e) {
      print('Error uploading profile picture: $e');
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_currentUser == null) return;

    try {
      String fileName = 'profile_pictures/${_currentUser!.uid}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'photoUrl': FieldValue.delete()});

      // Update cache with default image
      _prefs?.setString('photoUrl', 'https://picsum.photos/200/300.jpg');

      setState(() {
        _photoUrl = 'https://picsum.photos/200/300.jpg';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting profile picture: $e');
    }
  }

  Future<void> _updateUserName() async {
    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'name': _nameController.text.trim()});

        // Cache the updated name
        _prefs?.setString('name', _nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully!'),
        ));
      } catch (e) {
        print('Error updating name: $e');
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Clear SharedPreferences
      await _prefs?.clear();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to LoginScreen and clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SignUpScreen()),
            (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2) {
      // Stay on Profile page
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : _photoUrl != null
                        ? NetworkImage(_photoUrl!) as ImageProvider
                        : NetworkImage('https://picsum.photos/200/300.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                      color: Colors.blue,
                      iconSize: 30,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Delete photo button
            Center(
              child: ElevatedButton(
                onPressed: _deleteProfilePicture,
                child: Text('Delete Profile Picture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onEditingComplete: _updateUserName,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2, // Set to match the index for Bookings
          selectedItemColor: Colors.lightBlueAccent,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            // Handle navigation
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else if (index == 1) {
              // Navigate to Search Page if available
            } else if (index == 2) {

            }else if (index==3){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BookingsPage()),
              );
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Bookings',
            ),
          ],
        ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'login_screen.dart';
// import 'package:traveleasy/components/custom_app_bar.dart';
// import 'home_page.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ProfilePage extends StatefulWidget {
//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   File? _image;
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   int _selectedIndex = 2;
//
//   final _picker = ImagePicker();
//   final User? _currentUser = FirebaseAuth.instance.currentUser;
//   String? _photoUrl;
//   SharedPreferences? _prefs;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializePreferences();
//   }
//
//   // Initialize SharedPreferences
//   Future<void> _initializePreferences() async {
//     _prefs = await SharedPreferences.getInstance();
//     _loadCachedUserData();  // Load cached data first
//     _fetchUserDataFromFirestore();  // Fetch fresh data from Firestore
//   }
//
//   // Load cached data from SharedPreferences
//   void _loadCachedUserData() {
//     setState(() {
//       _nameController.text = _prefs?.getString('name') ?? 'Your Name';
//       _photoUrl = _prefs?.getString('photoUrl') ?? 'https://picsum.photos/200/300.jpg';
//       _emailController.text = _currentUser?.email ?? '';
//     });
//   }
//
//   // Fetch user data from Firestore and update cache
//   Future<void> _fetchUserDataFromFirestore() async {
//     if (_currentUser != null) {
//       DocumentSnapshot userData = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_currentUser!.uid)
//           .get();
//
//       // Update the cached data
//       _prefs?.setString('name', userData['name'] ?? 'Your Name');
//       _prefs?.setString('photoUrl', userData['photoUrl'] ?? 'https://picsum.photos/200/300.jpg');
//
//       // Update the UI with the fresh data
//       setState(() {
//         _nameController.text = userData['name'] ?? 'Your Name';
//         _photoUrl = userData['photoUrl'] ?? 'https://picsum.photos/200/300.jpg';
//       });
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.getImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       await _uploadProfilePicture();
//     }
//   }
//
//   Future<void> _uploadProfilePicture() async {
//     if (_image == null) return;
//
//     try {
//       String fileName = 'profile_pictures/${_currentUser!.uid}.jpg';
//       Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
//       UploadTask uploadTask = storageRef.putFile(_image!);
//
//       TaskSnapshot taskSnapshot = await uploadTask;
//       String downloadUrl = await taskSnapshot.ref.getDownloadURL();
//
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_currentUser!.uid)
//           .update({'photoUrl': downloadUrl});
//
//       // Cache the new photo URL
//       _prefs?.setString('photoUrl', downloadUrl);
//
//       setState(() {
//         _photoUrl = downloadUrl;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Profile picture uploaded successfully!')),
//       );
//     } catch (e) {
//       print('Error uploading profile picture: $e');
//     }
//   }
//
//   Future<void> _deleteProfilePicture() async {
//     if (_currentUser == null) return;
//
//     try {
//       String fileName = 'profile_pictures/${_currentUser!.uid}.jpg';
//       Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
//       await storageRef.delete();
//
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(_currentUser!.uid)
//           .update({'photoUrl': FieldValue.delete()});
//
//       // Update cache with default image
//       _prefs?.setString('photoUrl', 'https://picsum.photos/200/300.jpg');
//
//       setState(() {
//         _photoUrl = 'https://picsum.photos/200/300.jpg';
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Profile picture deleted successfully!')),
//       );
//     } catch (e) {
//       print('Error deleting profile picture: $e');
//     }
//   }
//
//   Future<void> _updateUserName() async {
//     if (_currentUser != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(_currentUser!.uid)
//             .update({'name': _nameController.text.trim()});
//
//         // Cache the updated name
//         _prefs?.setString('name', _nameController.text.trim());
//
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Profile updated successfully!'),
//         ));
//       } catch (e) {
//         print('Error updating name: $e');
//       }
//     }
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//
//     if (index == 0) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomePage()),
//       );
//     } else if (index == 2) {
//       // Stay on Profile page
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(title: 'Profile'),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: _image != null
//                         ? FileImage(_image!)
//                         : _photoUrl != null
//                         ? NetworkImage(_photoUrl!) as ImageProvider
//                         : NetworkImage('https://picsum.photos/200/300.jpg'),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: IconButton(
//                       icon: Icon(Icons.camera_alt, color: Colors.white),
//                       onPressed: _pickImage,
//                       color: Colors.blue,
//                       iconSize: 30,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),
//             // Delete photo button
//             Center(
//               child: ElevatedButton(
//                 onPressed: _deleteProfilePicture,
//                 child: Text('Delete Profile Picture'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               controller: _nameController,
//               decoration: InputDecoration(
//                 labelText: 'Name',
//                 border: OutlineInputBorder(),
//               ),
//               onEditingComplete: _updateUserName,
//             ),
//             SizedBox(height: 10),
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//               readOnly: true,
//             ),
//             SizedBox(height: 20),
//             ListTile(
//               leading: Icon(Icons.logout, color: Colors.red),
//               title: Text('Logout'),
//               onTap: () async {
//                 await FirebaseAuth.instance.signOut();
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => LoginScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.lightBlueAccent,
//         onTap: _onItemTapped,
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.search),
//             label: 'Search',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
