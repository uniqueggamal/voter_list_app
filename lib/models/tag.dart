class Tag {
  final int id;
  final String name;
  final String color;

  const Tag({required this.id, required this.name, required this.color});

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      color: map['color'] as String? ?? '#FF0000',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color};
  }

  Tag copyWith({int? id, String? name, String? color}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
