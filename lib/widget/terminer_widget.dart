import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gestion_tache/model/todo_model.dart';
import 'package:gestion_tache/services/database_service.dart';

class CompletedWidget extends StatefulWidget {
  @override
  _CompletedWidgetState createState() => _CompletedWidgetState();
}

class _CompletedWidgetState extends State<CompletedWidget> {
  User? user = FirebaseAuth.instance.currentUser;
  late String uid;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (user != null) {
      uid = user!.uid;
    } else {
      print("Utilisateur non connecté");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
        stream: _databaseService.completedtodos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            List<Todo> todos = snapshot.data!;
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
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Slidable(
                    key: ValueKey(todo.id),
                   
                    startActionPane:
                        ActionPane(motion: DrawerMotion(), children: [
                      
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
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        todo.description,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough
                        ),
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

 
}
