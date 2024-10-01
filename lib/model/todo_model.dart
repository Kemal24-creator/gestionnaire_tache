import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  final String startDate;
  final String endDate;
  final bool completed;
  final Timestamp timeStamp;

  Todo(
      {required this.id,
      required this.title,
      required this.description,
      required this.startDate,
      required this.endDate,
      required this.completed,
      required this.timeStamp});
}
