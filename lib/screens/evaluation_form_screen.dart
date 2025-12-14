import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';
import '../providers/employee_provider.dart';

class EvaluationFormScreen extends StatefulWidget {
  final Employee employee;
  const EvaluationFormScreen({super.key, required this.employee});

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _notesController = TextEditingController();
  double _score = 3.0; // Slider 1-5

  void _submit() {
    if (_notesController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan wajib diisi')));
        return;
    }
    
    final ev = Evaluation(
      id: const Uuid().v4(),
      employeeId: widget.employee.id,
      date: DateTime.now(),
      notes: _notesController.text,
      score: _score,
    );

    Provider.of<EmployeeProvider>(context, listen: false).addEvaluation(ev);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Evaluasi: ${widget.employee.nama}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Berikan nilai untuk ${widget.employee.nama}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text("Skor Kinerja (1-5)"),
            Slider(
              value: _score,
              min: 1,
              max: 5,
              divisions: 4,
              label: _score.toString(),
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: "Catatan Evaluasi",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text("SIMPAN EVALUASI"),
            ),
          ],
        ),
      ),
    );
  }
}
