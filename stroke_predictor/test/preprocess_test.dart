import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_predictor/utils/preprocess.dart';

void main() {
  test('One-hot encoding: Male + never smoked + Yes', () {
    final means = [0.0, 0.0, 0.0];
    final stds = [1.0, 1.0, 1.0];

    final f = buildFeatures(
      age: 60,
      glucose: 120,
      bmi: 25,
      hypertension: false,
      heartDisease: true,
      gender: 'Male',
      smoking: 'never smoked',
      everMarried: 'Yes',
      means: means,
      stds: stds,
    );

    expect(f[6], 1.0);  // gender__Male
    expect(f[10], 1.0); // smoking__never smoked
    expect(f[13], 1.0); // ever_married__Yes
    expect(f[4], 1.0);  // heart_disease true
  });

  test('Z-score scaling works when mean=0 std=1', () {
    final means = [0.0, 0.0, 0.0];
    final stds = [1.0, 1.0, 1.0];

    final f = buildFeatures(
      age: 10,
      glucose: 20,
      bmi: 30,
      hypertension: false,
      heartDisease: false,
      gender: 'Female',
      smoking: 'Unknown',
      everMarried: 'No',
      means: means,
      stds: stds,
    );

    expect(f[0], 10); // z(age)
    expect(f[1], 20); // z(glucose)
    expect(f[2], 30); // z(bmi)
  });
}
