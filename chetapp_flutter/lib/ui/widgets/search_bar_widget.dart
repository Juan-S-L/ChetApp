import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchBarWidget extends StatefulWidget {
  final Function(double lat, double lon) onPlaceSelected;
  const SearchBarWidget({super.key, required this.onPlaceSelected});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> _placePredictions = [];

  //! Función para obtener predicciones de la API de Nominatim (OpenStreetMap)
  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    final String url = 'https://nominatim.openstreetmap.org/search?q=$input&format=json&addressdetails=1&limit=5&bounded=1&viewbox=-73.7000,4.2000,-73.5000,4.0500';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _placePredictions = data;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //! Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar lugar',
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _getPlacePredictions(value); // Obtener predicciones de Nominatim
            },
          ),
        ),

        //! Mostrar predicciones
        if (_placePredictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: _placePredictions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_placePredictions[index]['display_name']),
                  onTap: () {
                    final lat = double.parse(_placePredictions[index]['lat']);
                    final lon = double.parse(_placePredictions[index]['lon']);
                    widget.onPlaceSelected(lat, lon);
                    setState(() {
                      _placePredictions = [];
                      searchController.clear();
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
