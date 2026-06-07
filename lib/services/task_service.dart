import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskService {
  static const String boxName = 'tasks_box';

  static Box<TaskModel> get box => Hive.box<TaskModel>(boxName);

  static List<TaskModel> getAllTasks() {
    final tasks = box.values.toList();
    _sortTasks(tasks);
    return tasks;
  }

  static List<TaskModel> getTasksByDate(DateTime date) {
    final tasks = box.values.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
    _sortTasks(tasks);
    return tasks;
  }

  static List<TaskModel> getTodayTasks() {
    return getTasksByDate(DateTime.now());
  }

  static void _sortTasks(List<TaskModel> tasks) {
    tasks.sort((a, b) {
      if (a.isPriority != b.isPriority) return a.isPriority ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
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

  static Future<void> clearAllTasks() async {
    await box.clear();
  }
}
