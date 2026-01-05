String? validateNonNegativeNumber(String label, String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter $label';
  }

  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return 'Enter a valid number';
  }

  if (parsed < 0) {
    return '$label cannot be negative';
  }

  return null;
}
