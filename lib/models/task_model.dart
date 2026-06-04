import 'package:hive/hive.dart';

class TaskModel {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final bool isDone;
  final bool isPriority;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.isDone = false,
    this.isPriority = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    bool? isDone,
    bool? isPriority,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
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
    return TaskModel(
      id: reader.readString(),
      title: reader.readString(),
      category: reader.readString(),
      date: reader.read() as DateTime,
      isDone: reader.readBool(),
      isPriority: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.category);
    writer.write(obj.date);
    writer.writeBool(obj.isDone);
    writer.writeBool(obj.isPriority);
  }
}