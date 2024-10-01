import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestion_tache/model/todo_model.dart';

class DatabaseService {
  final CollectionReference todoCollection =
      FirebaseFirestore.instance.collection("todos");

  User? user = FirebaseAuth.instance.currentUser;

  // Ajouter une tâche

  Future<DocumentReference> ajoutTache(String title, String description, String startDate, String endDate) async {
    return await todoCollection.add({
      'uid': user!.uid,
      'title': title,
      'description': description,
      'startDate' : startDate,
      'endDate' : endDate,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Modifier une tâche

  Future<void> updateTache(String id, String title, String description,String startDate, String endDate) async {
    final updatetodoCollection =
        FirebaseFirestore.instance.collection("todos").doc(id);

    return await updatetodoCollection
        .update({'title': title, 'description': description, 'startDate' : startDate, 'endDate' : endDate});
  }

  // Modifier status

  Future<void> updateTodoStatus(String id, bool completed) async {
    return await todoCollection.doc(id).update({"completed": completed});
  }

  // Supprimer une tache

  Future<void> deleteTodoTask(String id) async {
    return await todoCollection.doc(id).delete();
  }

  // Recupération des taches

  Stream<List<Todo>> get todos {
    return todoCollection
        .where('uid', isEqualTo: user!.uid)
        .where('completed', isEqualTo: false)
        .snapshots()
        .map(_todoListFromSnapshot);
  }

  // Recupérarion des taches terminer

  Stream<List<Todo>> get completedtodos {
    return todoCollection
        .where('uid', isEqualTo: user!.uid)
        .where('completed', isEqualTo: true)
        .snapshots()
        .map(_todoListFromSnapshot);
  }

  List<Todo> _todoListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return Todo(
          id: doc.id,
          title: doc['title'] ?? '',
          description: doc['description'] ?? '',
          startDate: doc['startDate'] ?? '',
          endDate: doc['endDate'] ?? '',
          completed: doc['completed'] ?? false,
          timeStamp: doc['createdAt'] ?? '');
    }).toList();
  }
}
