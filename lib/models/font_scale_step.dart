enum FontScaleStep {
  extraSmall(-3, 0.85),
  small(-2, 0.90),
  slightlySmall(-1, 0.95),
  normal(0, 1.0),
  slightlyLarge(1, 1.10),
  large(2, 1.20),
  extraLarge(3, 1.30);

  const FontScaleStep(this.step, this.scale);

  final int step;
  final double scale;

  static const defaultValue = FontScaleStep.normal;

  bool get isDefault => this == defaultValue;
  double get sliderValue => step.toDouble();
  int get percent => (scale * 100).round();
  String get label => '$percent%';
  String get storageValue => step.toString();

  static FontScaleStep fromStorage(String? value) {
    return fromStep(int.tryParse(value ?? ''));
  }

  static FontScaleStep fromSliderValue(double value) {
    return fromStep(value.round());
  }

  static FontScaleStep fromStep(int? step) {
    for (final value in FontScaleStep.values) {
      if (value.step == step) {
        return value;
      }
    }
    return defaultValue;
  }
}
