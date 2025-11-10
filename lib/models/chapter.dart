class Chapter {
  final String id;
  final int allocSec;
  final List<String> alternatives;

  Chapter({
    required this.id,
    required this.allocSec,
    required this.alternatives,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String? ?? '',
      allocSec: json['alloc_sec'] as int? ?? 0,
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alloc_sec': allocSec,
      'alternatives': alternatives,
    };
  }
}

