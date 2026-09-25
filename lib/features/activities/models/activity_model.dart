import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String organization;
  final String ward;
  final String visibility; // 🚀 'ward', 'stake', 'leadership'

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.organization,
    required this.ward,
    this.visibility = 'ward',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'organization': organization,
      'ward': ward,
      'visibility': visibility,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] is Timestamp ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      organization: map['organization'] ?? 'Barrio',
      ward: map['ward'] ?? '',
      visibility: map['visibility'] ?? (map['ward'] == 'Estaca' ? 'stake' : 'ward'),
    );
  }
}