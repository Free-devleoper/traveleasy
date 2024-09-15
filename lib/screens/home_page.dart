import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';
import 'package:traveleasy/components/custom_app_bar.dart';
import 'package:traveleasy/screens/booking_screen.dart'; // Import the booking screen
import 'bookingPage.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // For managing bottom navigation
  List<Map<String, dynamic>> flights = []; // List of flights
  bool isLoading = false; // Loading state

  String? selectedOrigin; // Selected origin IATA code
  String? selectedDestination; // Selected destination IATA code

  final List<Map<String, String>> airports = [
    {"name": "John F. Kennedy International Airport", "iata": "JFK"},
    {"name": "Los Angeles International Airport", "iata": "LAX"},
    {"name": "Chicago O'Hare International Airport", "iata": "ORD"},
    {"name": "Dallas/Fort Worth International Airport", "iata": "DFW"},
    {"name": "Denver International Airport", "iata": "DEN"},
    {"name": "San Francisco International Airport", "iata": "SFO"},
    {"name": "Seattle-Tacoma International Airport", "iata": "SEA"},
    {"name": "Miami International Airport", "iata": "MIA"},
    {"name": "Orlando International Airport", "iata": "MCO"},
    {"name": "Boston Logan International Airport", "iata": "BOS"},
  ];

  // Fetch flights from the API based on selected origin and destination
  Future<void> fetchFlights() async {
    if (selectedOrigin == null || selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both origin and destination')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      flights = [];
    });

    final headers = {
      'X-Access-Token': '58e0e2faea03fc5941fc749b5ef3f886'
    };

    final uri = Uri.parse(
      'https://api.travelpayouts.com/v2/prices/month-matrix?currency=usd&show_to_affiliates=true&origin=$selectedOrigin&destination=$selectedDestination',
    );

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          flights = data.map((flight) {
            return {
              'depart_date': flight['depart_date'],
              'origin': flight['origin'],
              'destination': flight['destination'],
              'value': flight['value'].toString(),
              'gate': flight['gate'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load flights');
      }
    } catch (error) {
      print('Error fetching flights: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to corresponding pages
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      // Navigate to Search Page if available
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>
            BookingsPage()), // Add navigation to BookingsPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Flights'), // Use custom app bar
      body: RefreshIndicator(
        onRefresh: fetchFlights,
        child: Column(
          children: [
            // Dropdown for selecting origin
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Origin Airport',
                  border: OutlineInputBorder(),
                ),
                value: selectedOrigin,
                onChanged: (value) {
                  setState(() {
                    selectedOrigin = value;
                  });
                },
                items: airports.map<DropdownMenuItem<String>>((
                    Map<String, String> airport) {
                  return DropdownMenuItem<String>(
                    value: airport['iata'],
                    child: Text("${airport['name']} (${airport['iata']})"),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            // Dropdown for selecting destination
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Destination Airport',
                  border: OutlineInputBorder(),
                ),
                value: selectedDestination,
                onChanged: (value) {
                  setState(() {
                    selectedDestination = value;
                  });
                },
                items: airports.map<DropdownMenuItem<String>>((
                    Map<String, String> airport) {
                  return DropdownMenuItem<String>(
                    value: airport['iata'],
                    child: Text("${airport['name']} (${airport['iata']})"),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            // Search flights button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: fetchFlights,
                child: Text('Search Flights'),
              ),
            ),
            // Display list of flights or a loading indicator
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: flights.length,
                itemBuilder: (context, index) {
                  final flight = flights[index];
                  return ListTile(
                    title: Text(
                      '${flight['origin']} to ${flight['destination']}',
                    ),
                    subtitle: Text(
                      'Price: \$${flight['value']} - Gate: ${flight['gate']}',
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(flight: flight),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
