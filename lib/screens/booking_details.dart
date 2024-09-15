import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  BookingDetailsPage({required this.booking});

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool _isLoading = false;

  Future<void> _deleteBooking() async {
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

      // Find and delete the booking from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('flights')
          .where('userId', isEqualTo: userId)
          .where('depart_date', isEqualTo: widget.booking['depart_date'])
          .where('origin', isEqualTo: widget.booking['origin'])
          .where('destination', isEqualTo: widget.booking['destination'])
          .where('value', isEqualTo: widget.booking['value'])
          .where('gate', isEqualTo: widget.booking['gate'])
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking deleted successfully!')),
      );

      // Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting booking: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            _buildDetailRow(Icons.date_range, 'Departure Date:', widget.booking['depart_date']),
            _buildDetailRow(Icons.flight_takeoff, 'Origin:', widget.booking['origin']),
            _buildDetailRow(Icons.flight_land, 'Destination:', widget.booking['destination']),
            _buildDetailRow(Icons.attach_money, 'Price:', '\$${widget.booking['value']}'),
            _buildDetailRow(Icons.airplanemode_active, 'Gate:', widget.booking['gate']),
            SizedBox(height: 16),
            // Delete booking button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deleteBooking,
                child: _isLoading
                    ? CircularProgressIndicator() // Show loading indicator
                    : Text('Delete Booking'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.red, // White text color
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
