import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightService {
  final String apiKey = '58e0e2faea03fc5941fc749b5ef3f886';

  Future<dynamic> getFlights(String origin, String destination) async {
    final url = 'https://api.travelpayouts.com/v2/prices/latest?origin=$origin&destination=$destination&token=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body); // Parse and return the response
    } else {
      throw Exception('Failed to load flight data');
    }
  }
}
