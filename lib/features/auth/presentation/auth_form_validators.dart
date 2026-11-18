String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nama wajib diisi.';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email wajib diisi.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
    return 'Format email tidak valid.';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Kata sandi wajib diisi.';
  }
  if (value.length < 8) {
    return 'Kata sandi minimal 8 karakter.';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Konfirmasi kata sandi wajib diisi.';
  }
  if (value != password) {
    return 'Konfirmasi kata sandi tidak sama.';
  }
  return null;
}
