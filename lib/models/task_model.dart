import 'package:hive/hive.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final bool isDone;
  final bool isPriority;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
    this.reminderTime,
    this.isDone = false,
    this.isPriority = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
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
      description: description ?? this.description,
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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      date: fields[3] as DateTime,
      createdAt: fields[4] as DateTime? ?? DateTime.now(),
      reminderTime: fields[5] as DateTime?,
      isDone: fields[6] as bool? ?? false,
      isPriority: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.description);
    writer.writeByte(3);
    writer.write(obj.date);
    writer.writeByte(4);
    writer.write(obj.createdAt);
    writer.writeByte(5);
    writer.write(obj.reminderTime);
    writer.writeByte(6);
    writer.write(obj.isDone);
    writer.writeByte(7);
    writer.write(obj.isPriority);
  }
}