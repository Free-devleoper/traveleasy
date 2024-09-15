import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> flight;

  BookingScreen({required this.flight});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isLoading = false; // Track loading state
  bool _isBooked = false; // Track if booking is confirmed

  // Reference to the Firestore collection
  final CollectionReference flightsCollection =
  FirebaseFirestore.instance.collection('flights');

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's ID
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is currently logged in')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      String userId = user.uid;

      // Add flight information to Firestore
      await flightsCollection.add({
        'userId': userId,
        'depart_date': widget.flight['depart_date'],
        'origin': widget.flight['origin'],
        'destination': widget.flight['destination'],
        'value': widget.flight['value'],
        'gate': widget.flight['gate'],
        'bookingDate': Timestamp.now(), // Add booking timestamp
      });

      setState(() {
        _isLoading = false;
        _isBooked = true;
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed!')),
      );

      // Navigate back to the previous screen
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.lightBlueAccent, // Use primary color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flight details in a form-like layout
            Text(
              'Flight Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow(Icons.date_range, 'Departure Date:', widget.flight['depart_date']),
            _buildDetailRow(Icons.flight_takeoff, 'Origin:', widget.flight['origin']),
            _buildDetailRow(Icons.flight_land, 'Destination:', widget.flight['destination']),
            _buildDetailRow(Icons.attach_money, 'Price:', '\$${widget.flight['value']}'),
            _buildDetailRow(Icons.airplanemode_active, 'Gate:', widget.flight['gate']),
            SizedBox(height: 16),
            // Confirm booking button
            Center(
              child: ElevatedButton(
                onPressed: _isBooked || _isLoading ? null : _confirmBooking,
                child: _isLoading
                    ? CircularProgressIndicator() // Show loading indicator
                    : Text('Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent, // Match the app bar color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightBlueAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label $value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
