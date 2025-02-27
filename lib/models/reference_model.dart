enum ReferenceType { note, password, event }

class ItemReference {
  final String id;
  final String title;
  final ReferenceType type;
  final int index;

  ItemReference({
    required this.id,
    required this.title,
    required this.type,
    required this.index,
  });
}