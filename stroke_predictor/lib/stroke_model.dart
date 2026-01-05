import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class StrokeModel {
  Interpreter? _interpreter;

  late List<String> _featureOrder;
  late List<double> _means;
  late List<double> _stds;

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    // 1) Load TFLite model from assets
    _interpreter ??=
        await Interpreter.fromAsset('assets/models/stroke_dnn.tflite');

    // 2) Load preproc.json
    final jsonStr =
        await rootBundle.loadString('assets/models/preproc.json');
    final Map<String, dynamic> preproc = jsonDecode(jsonStr);

    _featureOrder =
        (preproc['feature_order'] as List).map((e) => e.toString()).toList();

    final scaler = preproc['scaler'] as Map<String, dynamic>;
    _means = (scaler['means'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    _stds = (scaler['stds'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    _loaded = true;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
  }

  double _z(double value, int idx) {
    if (idx < 0 || idx >= _means.length) return value;
    final std = _stds[idx];
    if (std == 0) return 0.0;
    return (value - _means[idx]) / std;
  }

  Future<double> predict({
    required double age,
    required double glucose,
    required double bmi,
    required bool hypertension,
    required bool heartDisease,
    required String gender, // "Male", "Female", "Other"
    required String smoking, // "Unknown", "formerly smoked", "never smoked", "smokes"
    required String everMarried, // "No", "Yes"
  }) async {
    if (!_loaded || _interpreter == null) {
      throw StateError('Model not loaded. Call load() first.');
    }

    // feature_order from preproc.json:
    // [
    //   "age",
    //   "glucose",
    //   "bmi",
    //   "hypertension",
    //   "heart_disease",
    //   "gender__Female",
    //   "gender__Male",
    //   "gender__Other",
    //   "smoking_status__Unknown",
    //   "smoking_status__formerly smoked",
    //   "smoking_status__never smoked",
    //   "smoking_status__smokes",
    //   "ever_married__No",
    //   "ever_married__Yes"
    // ]

    final features = List<double>.filled(_featureOrder.length, 0.0);

    // Numeric (standardised)
    features[0] = _z(age, 0);      // age
    features[1] = _z(glucose, 1);  // glucose
    features[2] = _z(bmi, 2);      // bmi

    // Binary
    features[3] = hypertension ? 1.0 : 0.0;
    features[4] = heartDisease ? 1.0 : 0.0;

    // Gender one-hot: Female, Male, Other
    switch (gender) {
      case 'Female':
        features[5] = 1.0;
        break;
      case 'Male':
        features[6] = 1.0;
        break;
      case 'Other':
        features[7] = 1.0;
        break;
      default:
        // default: nothing set (all zeros)
        break;
    }

    // Smoking one-hot
    switch (smoking) {
      case 'Unknown':
        features[8] = 1.0;
        break;
      case 'formerly smoked':
        features[9] = 1.0;
        break;
      case 'never smoked':
        features[10] = 1.0;
        break;
      case 'smokes':
        features[11] = 1.0;
        break;
      default:
        break;
    }

    // Ever married one-hot
    switch (everMarried) {
      case 'No':
        features[12] = 1.0;
        break;
      case 'Yes':
        features[13] = 1.0;
        break;
      default:
        break;
    }

    // Shape: [1, num_features]
    final input = [features];

    // Output: assuming [1, 1] with a single probability
    final output = List.generate(1, (_) => List.filled(1, 0.0));

    _interpreter!.run(input, output);

    final prob = output[0][0];
    return prob.clamp(0.0, 1.0);
  }
}
