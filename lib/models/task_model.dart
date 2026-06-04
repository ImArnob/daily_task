import 'package:hive/hive.dart';

class TaskModel {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isDone;
  final bool isPriority;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.createdAt,
    this.reminderTime,
    this.isDone = false,
    this.isPriority = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? reminderTime,
    bool clearReminder = false,
    bool? isDone,
    bool? isPriority,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      reminderTime: clearReminder ? null : reminderTime ?? this.reminderTime,
      isDone: isDone ?? this.isDone,
      isPriority: isPriority ?? this.isPriority,
    );
  }
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final fields = reader.readMap();

    return TaskModel(
      id: fields['id'] as String,
      title: fields['title'] as String,
      category: fields['category'] as String,
      date: fields['date'] as DateTime,
      createdAt: fields['createdAt'] as DateTime? ?? DateTime.now(),
      reminderTime: fields['reminderTime'] as DateTime?,
      isDone: fields['isDone'] as bool? ?? false,
      isPriority: fields['isPriority'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeMap({
      'id': obj.id,
      'title': obj.title,
      'category': obj.category,
      'date': obj.date,
      'createdAt': obj.createdAt,
      'reminderTime': obj.reminderTime,
      'isDone': obj.isDone,
      'isPriority': obj.isPriority,
    });
  }
}
