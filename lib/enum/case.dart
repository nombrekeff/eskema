enum Case {
  lower,
  upper;

  String get name {
    switch (this) {
      case Case.lower:
        return 'lower';
      case Case.upper:
        return 'upper';
    }
  }

  @override
  String toString() => name;
}
