class Validators {
  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Champ requis' : null;
}
