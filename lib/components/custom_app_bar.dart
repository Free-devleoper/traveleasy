import 'package:flutter/material.dart';
import 'package:traveleasy/screens/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  CustomAppBar({this.title = '', this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 150, // Adjust the width to fit the text
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0), // Small padding for alignment
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Traveleasy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Text(title),
      centerTitle: true,
      backgroundColor: Colors.lightBlueAccent,
      automaticallyImplyLeading: showBackButton, // If true, shows the back button
      actions: [
        IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            // Navigate to Profile Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
