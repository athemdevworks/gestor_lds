import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;      // Ej: "Capilla", "Parque", "Zoom"
  final String organization;  // Ej: "Primaria", "Barrio", "Jóvenes"

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.organization,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'organization': organization,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      organization: map['organization'] ?? 'Barrio',
    );
  }
}