import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskService {
  static const String boxName = 'tasks_box';

  static Box<TaskModel> get box => Hive.box<TaskModel>(boxName);

  static List<TaskModel> getAllTasks() {
    return box.values.toList();
  }

  static List<TaskModel> getTasksByDate(DateTime date) {
    return box.values.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  static Future<void> addTask(TaskModel task) async {
    await box.put(task.id, task);
  }

  static Future<void> updateTask(TaskModel task) async {
    await box.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await box.delete(id);
  }

  static int doneCountByDate(DateTime date) {
    return getTasksByDate(date).where((task) => task.isDone).length;
  }
}