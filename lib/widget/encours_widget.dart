import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gestion_tache/model/todo_model.dart';
import 'package:gestion_tache/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class PendingWidget extends StatefulWidget {
  @override
  _PendingWidgetState createState() => _PendingWidgetState();
}

class _PendingWidgetState extends State<PendingWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  late String uid;

  final DatabaseService _databaseService = DatabaseService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    if (user != null) {
      uid = user!.uid;
    } else {
      print("Utilisateur non connecté");
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();  // Initialisation des fuseaux horaires
  }

  String calculateCountdown(String startDate, String endDate) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    try {
      DateTime start = formatter.parse(startDate);
      DateTime end = formatter.parse(endDate);
      final Duration difference = end.difference(DateTime.now());
      if (difference.isNegative) {
        return 'Terminé';
      }
      return '${difference.inDays} jours restants';
    } catch (e) {
      return 'Date invalide';
    }
  }

  Future<void> _scheduleNotification(String title, String body, DateTime date) async {
    final scheduledNotificationDateTime = date.subtract(Duration(days: 1));
    tz.TZDateTime scheduledDateTime = tz.TZDateTime.from(scheduledNotificationDateTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
        stream: _databaseService.todos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
          List<Todo> todos = snapshot.data!;
          for (Todo todo in todos) {
            final DateTime endDate = DateFormat('dd/MM/yyyy').parse(todo.endDate);
            if (endDate.isAfter(DateTime.now().subtract(Duration(days: 1))) && 
                endDate.isBefore(DateTime.now().add(Duration(days: 1)))) {
              // Si la date de fin est aujourd'hui ou demain
              String notificationMessage = (endDate.isAtSameMomentAs(DateTime.now()))
                  ? "Aujourd'hui c'est la date limite pour: ${todo.title}"
                  : "Il reste 1 jour pour: ${todo.title}";

              _scheduleNotification("Rappel de Tâche", notificationMessage, endDate);
            }
          }
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                Todo todo = todos[index];

                final DateTime dt = todo.timeStamp.toDate();

                return Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Slidable(
                    key: ValueKey(todo.id),
                    endActionPane:
                        ActionPane(motion: DrawerMotion(), children: [
                      SlidableAction(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.done,
                          label: "Valider",
                          onPressed: (context) {
                            _databaseService.updateTodoStatus(todo.id, true);
                          })
                    ]),
                    startActionPane:
                        ActionPane(motion: DrawerMotion(), children: [
                      SlidableAction(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: "Modifier",
                          onPressed: (context) {
                            _showTaskDialog(context, todo: todo);
                          }),
                      SlidableAction(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: "Supprimer",
                          onPressed: (context) async {
                            await _databaseService.deleteTodoTask(todo.id);
                          })
                    ]),
                    child: ListTile(
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(todo.description),
                          SizedBox(height: 4),
                          Text(
                            'Début: ${todo.startDate}, Fin: ${todo.endDate}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            calculateCountdown(todo.startDate, todo.endDate),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${dt.day} / ${dt.month} / ${dt.year}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text('Aucune tâche trouvée.'),
            );
          }
        });
  }

  void _showTaskDialog(BuildContext context, {Todo? todo}) {
    final TextEditingController _titleController =
        TextEditingController(text: todo?.title);
    final TextEditingController _descriptionController =
        TextEditingController(text: todo?.description);
    final TextEditingController _startDateController =
        TextEditingController(text: todo?.startDate ?? '');
    final TextEditingController _endDateController =
        TextEditingController(text: todo?.endDate ?? '');

    Future<void> _selectDate(
        BuildContext context, TextEditingController controller) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        setState(() {
          controller.text =
              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            todo == null ? "Ajouter Tâche" : "Modifier Tâche",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Titre",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _startDateController),
                    decoration: InputDecoration(
                      labelText: "Date de début",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _endDateController),
                    decoration: InputDecoration(
                      labelText: "Date de fin",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (todo == null) {
                  await _databaseService.ajoutTache(
                    _titleController.text,
                    _descriptionController.text,
                    _startDateController.text,
                    _endDateController.text,
                  );
                } else {
                  await _databaseService.updateTache(
                    todo.id,
                    _titleController.text,
                    _descriptionController.text,
                    _startDateController.text,
                    _endDateController.text,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(todo == null ? "Enregistrer" : "Modifier"),
            ),
          ],
        );
      },
    );
  }
}
