import 'package:flutter/material.dart';
import 'package:gestion_tache/login-screen.dart';
import 'package:gestion_tache/model/todo_model.dart';
import 'package:gestion_tache/services/auth_service.dart';
import 'package:gestion_tache/services/database_service.dart';
import 'package:gestion_tache/widget/encours_widget.dart';
import 'package:gestion_tache/widget/terminer_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _buttonIndex = 0;

  final List<Widget> _widget = [
    
    PendingWidget(),
    
    CompletedWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1d2630),
      appBar: AppBar(
        backgroundColor: Color(0xFF1d2630),
        foregroundColor: Colors.white,
        title: Text("Mes Tâches"),
        actions: [
          IconButton(
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              icon: Icon(Icons.exit_to_app))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _buttonIndex = 0; // Pour PendingWidget
                    });
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width / 2.2,
                    decoration: BoxDecoration(
                        color: _buttonIndex == 0 ? Colors.indigo : Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "En cours",
                        style: TextStyle(
                            fontSize: _buttonIndex == 0 ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: _buttonIndex == 0
                                ? Colors.white
                                : Colors.black38),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _buttonIndex = 1; // Pour CompletedWidget
                    });
                  },
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width / 2.2,
                    decoration: BoxDecoration(
                        color: _buttonIndex == 1 ? Colors.indigo : Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "Terminer",
                        style: TextStyle(
                            fontSize: _buttonIndex == 1 ? 16 : 14,
                            fontWeight: FontWeight.w500,
                            color: _buttonIndex == 1
                                ? Colors.white
                                : Colors.black38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // Affiche le widget correspondant à l'index sélectionné
            _widget[_buttonIndex],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () {
          _showTaskDialog(context);
        },
      ),
    );
  }

  void _showTaskDialog(BuildContext context, {Todo? todo}) {
    final TextEditingController _titleController = TextEditingController(text: todo?.title);
    final TextEditingController _descriptionController = TextEditingController(text: todo?.description);
    final TextEditingController _startDateController = TextEditingController(text: todo?.startDate ?? '');
    final TextEditingController _endDateController = TextEditingController(text: todo?.endDate ?? '');

    final DatabaseService _databaseService = DatabaseService();

    Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        setState(() {
          controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
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
