import 'utils/validators.dart';

import 'history_db.dart';
import 'history_screen.dart';

import 'package:flutter/material.dart';
import 'stroke_model.dart';  // ⬅️ use your TFLite wrapper


void main() {
  runApp(const StrokeApp());
}

class StrokeApp extends StatelessWidget {
  const StrokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stroke Risk Predictor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StrokeFormPage(),
    );
  }
}

class StrokeFormPage extends StatefulWidget {
  const StrokeFormPage({super.key});

  @override
  State<StrokeFormPage> createState() => _StrokeFormPageState();
}

class _StrokeFormPageState extends State<StrokeFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for numeric inputs
  final _ageController = TextEditingController();
  final _bmiController = TextEditingController();
  final _glucoseController = TextEditingController();

  // Categorical / binary fields
  String _gender = 'Male';
  String _everMarried = 'No';
  bool _hypertension = false;
  bool _heartDisease = false;
  String _smokingStatus = 'never smoked';

  // ML model state
  late final StrokeModel _model;
  bool _modelReady = false;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _model = StrokeModel();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await _model.load();
      setState(() => _modelReady = true);
    } catch (e) {
      setState(() => _modelError = 'Failed to load model: $e');
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _bmiController.dispose();
    _glucoseController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _onPredict() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_modelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model still loading, please wait…')),
      );
      return;
    }

    _formKey.currentState!.save();

    final age = double.tryParse(_ageController.text.trim()) ?? 0.0;
    final bmi = double.tryParse(_bmiController.text.trim()) ?? 0.0;
    final glucose = double.tryParse(_glucoseController.text.trim()) ?? 0.0;

    // These strings must match categories in preproc.json
    final gender = _gender;           // "Male", "Female", "Other"
    final smoking = _smokingStatus;   // "never smoked", "formerly smoked", "smokes", "Unknown"
    final everMarried = _everMarried; // "No", "Yes"

    // Call the real TFLite model
    final prob = await _model.predict(
      age: age,
      glucose: glucose,
      bmi: bmi,
      hypertension: _hypertension,
      heartDisease: _heartDisease,
      gender: gender,
      smoking: smoking,
      everMarried: everMarried,
    );

    final pct = (prob * 100).toStringAsFixed(1);

    String riskText;
    if (prob < 0.2) {
      riskText = 'Low estimated stroke risk';
    } else if (prob < 0.5) {
      riskText = 'Moderate estimated stroke risk';
    } else {
      riskText = 'High estimated stroke risk';
    }

        // 🔽save prediction to local SQLite history
    await HistoryDatabase.instance.insertPrediction(
      probability: prob,
      riskLevel: riskText,
      age: age,
      bmi: bmi,
      glucose: glucose,
    );


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stroke Risk Result'),
        content: Text(
          '$riskText\n\nEstimated probability: $pct%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) => validateNonNegativeNumber(label, value),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroke Risk Predictor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_modelError != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _modelError!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (!_modelReady)
              const LinearProgressIndicator(minHeight: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNumberField(
                          _ageController, 'Age (years)', 'e.g. 60'),
                      const SizedBox(height: 12),
                      _buildNumberField(
                          _bmiController, 'BMI', 'e.g. 27.5 (kg/m²)'),
                      const SizedBox(height: 12),
                      _buildNumberField(_glucoseController,
                          'Average glucose level (mg/dL)', 'e.g. 120'),
                      const SizedBox(height: 16),

                      // Gender dropdown
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) =>
                            setState(() => _gender = v ?? 'Male'),
                      ),
                      const SizedBox(height: 12),

                      // Ever married
                      DropdownButtonFormField<String>(
                        value: _everMarried,
                        decoration: const InputDecoration(
                          labelText: 'Ever married',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'No', child: Text('No')),
                          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                        ],
                        onChanged: (v) =>
                            setState(() => _everMarried = v ?? 'No'),
                      ),
                      const SizedBox(height: 12),

                      // Hypertension & heart disease switches
                      SwitchListTile(
                        title: const Text('Hypertension'),
                        value: _hypertension,
                        onChanged: (v) =>
                            setState(() => _hypertension = v),
                      ),
                      SwitchListTile(
                        title: const Text('Heart disease'),
                        value: _heartDisease,
                        onChanged: (v) =>
                            setState(() => _heartDisease = v),
                      ),
                      const SizedBox(height: 12),

                      // Smoking status
                      DropdownButtonFormField<String>(
                        value: _smokingStatus,
                        decoration: const InputDecoration(
                          labelText: 'Smoking status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'never smoked',
                              child: Text('Never smoked')),
                          DropdownMenuItem(
                              value: 'formerly smoked',
                              child: Text('Formerly smoked')),
                          DropdownMenuItem(
                              value: 'smokes',
                              child: Text('Smokes currently')),
                          DropdownMenuItem(
                              value: 'Unknown',
                              child: Text('Unknown / not sure')),
                        ],
                        onChanged: (v) =>
                            setState(() => _smokingStatus = v ?? 'never smoked'),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _modelReady ? _onPredict : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Estimate Stroke Risk',
                          style: TextStyle(fontSize: 16),
                        ),

              
                      ),
                      const SizedBox(height: 12),

OutlinedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  },
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
  ),
  child: const Text(
    'View Prediction History',
    style: TextStyle(fontSize: 15),
  ),
),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

