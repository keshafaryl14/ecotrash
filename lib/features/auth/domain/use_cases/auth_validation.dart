String? normalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('62')) {
    digits = '62$digits'.replaceFirst('6262', '62');
  } else if (digits.startsWith('0')) {
    digits = '62${digits.substring(1)}';
  } else if (digits.isNotEmpty) {
    digits = '62$digits';
  }
  if (digits.isEmpty) return null;
  if (!RegExp(r'^62\d{8,12}$').hasMatch(digits)) return null;
  return '+$digits';
}

bool isValidEmail(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());

bool isValidPassword(String password) =>
    password.length >= 8 &&
    RegExp(r'[A-Za-z]').hasMatch(password) &&
    RegExp(r'\d').hasMatch(password);

int passwordStrength(String password) {
  var strength = 0;
  if (password.length >= 8) strength++;
  if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
  if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password)) {
    strength++;
  }
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;
  return strength;
}
