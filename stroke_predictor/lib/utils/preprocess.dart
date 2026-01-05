List<double> buildFeatures({
  required double age,
  required double glucose,
  required double bmi,
  required bool hypertension,
  required bool heartDisease,
  required String gender,
  required String smoking,
  required String everMarried,
  required List<double> means,
  required List<double> stds,
}) {
  double z(double value, int idx) {
    final std = stds[idx];
    if (std == 0) return 0.0;
    return (value - means[idx]) / std;
  }

  final f = List<double>.filled(14, 0.0);

  f[0] = z(age, 0);
  f[1] = z(glucose, 1);
  f[2] = z(bmi, 2);

  f[3] = hypertension ? 1.0 : 0.0;
  f[4] = heartDisease ? 1.0 : 0.0;

  if (gender == 'Female') f[5] = 1.0;
  if (gender == 'Male') f[6] = 1.0;
  if (gender == 'Other') f[7] = 1.0;

  if (smoking == 'Unknown') f[8] = 1.0;
  if (smoking == 'formerly smoked') f[9] = 1.0;
  if (smoking == 'never smoked') f[10] = 1.0;
  if (smoking == 'smokes') f[11] = 1.0;

  if (everMarried == 'No') f[12] = 1.0;
  if (everMarried == 'Yes') f[13] = 1.0;

  return f;
}
