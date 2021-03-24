// Sponsor: Test class.
class Sponsor {
  const Sponsor(this.name);

  /// Sponsor name
  final String name;

  @override
  String toString() {
    return 'Sponsor: $name';
  }

  @override
  bool operator ==(Object other) =>
      other is Sponsor && other.hashCode == hashCode;

  @override
  int get hashCode => name.hashCode;
}
