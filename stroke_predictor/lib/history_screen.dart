import 'package:flutter/material.dart';
import 'history_db.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryDatabase.instance.getPredictions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prediction History")),
      body: FutureBuilder(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text("No history available."));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final row = items[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    "${row['riskLevel']}  (${(row['probability'] * 100).toStringAsFixed(1)}%)",
                  ),
                  subtitle: Text(
                    "Age: ${row['age']},  BMI: ${row['bmi']},  Glucose: ${row['glucose']}\n"
                    "Date: ${row['createdAt']}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
