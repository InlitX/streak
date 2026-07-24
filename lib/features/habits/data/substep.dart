class Substep {
  const Substep({required this.id, required this.title});

  final String id;
  final String title;

  Substep copyWith({String? title}) =>
      Substep(id: id, title: title ?? this.title);

  Map<String, dynamic> toMap() => {'id': id, 'title': title};

  factory Substep.fromMap(Map<String, dynamic> map) => Substep(
        id: map['id'] as String,
        title: (map['title'] ?? '') as String,
      );
}
