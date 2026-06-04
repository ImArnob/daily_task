import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/notification_service.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum BottomTab { home, calendar }

class _HomeScreenState extends State<HomeScreen> {
  int getNotificationId(String id) {
    return id.hashCode.abs() % 100000;
  }

  DateTime selectedDate = DateTime.now();
  BottomTab currentTab = BottomTab.home;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  bool isPriority = false;

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String getGreetingIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 21) {
      return '🌙';
    } else {
      return '🌌';
    }
  }

  double getProgress(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((task) => task.isDone).length;
    return done / tasks.length;
  }

  void openAddTaskSheet({DateTime? taskDate, TaskModel? oldTask}) {
    final bool isEditMode = oldTask != null;

    titleController.text = oldTask?.title ?? '';
    categoryController.text = oldTask?.category ?? '';
    isPriority = oldTask?.isPriority ?? false;

    DateTime pickedDate = oldTask?.date ?? taskDate ?? selectedDate;
    TimeOfDay? pickedReminderTime = oldTask?.reminderTime == null
        ? null
        : TimeOfDay.fromDateTime(oldTask!.reminderTime!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xffF8F7F1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditMode ? 'Edit Task' : 'Add New Task',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      DateFormat('EEEE, MMM d').format(pickedDate),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: titleController,
                      maxLines: 2,
                      minLines: 1,
                      decoration: inputDecoration('Task title'),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: categoryController,
                      decoration: inputDecoration('Category e.g. Work, Study'),
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Task Date'),
                      subtitle: Text(
                        DateFormat('MMM d, yyyy').format(pickedDate),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (date != null) {
                          setSheetState(() {
                            pickedDate = date;
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Reminder'),
                      subtitle: Text(
                        pickedReminderTime == null
                            ? 'No reminder selected'
                            : pickedReminderTime!.format(context),
                      ),
                      trailing: pickedReminderTime == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setSheetState(() {
                                  pickedReminderTime = null;
                                });
                              },
                            ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: pickedReminderTime ?? TimeOfDay.now(),
                        );

                        if (time != null) {
                          setSheetState(() {
                            pickedReminderTime = time;
                          });
                        }
                      },
                    ),

                    SwitchListTile(
                      value: isPriority,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Priority task'),
                      activeThumbColor: const Color(0xff123B69),
                      onChanged: (value) {
                        setSheetState(() {
                          isPriority = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff123B69),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          final navigator = Navigator.of(context);

                          if (titleController.text.trim().isEmpty) return;

                          DateTime? reminderDateTime;

                          if (pickedReminderTime != null) {
                            reminderDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedReminderTime!.hour,
                              pickedReminderTime!.minute,
                            );
                          }

                          final taskId =
                              oldTask?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString();

                          final task = TaskModel(
                            id: taskId,
                            title: titleController.text.trim(),
                            category: categoryController.text.trim().isEmpty
                                ? 'Standard'
                                : categoryController.text.trim(),
                            date: pickedDate,
                            createdAt: oldTask?.createdAt ?? DateTime.now(),
                            reminderTime: reminderDateTime,
                            isDone: oldTask?.isDone ?? false,
                            isPriority: isPriority,
                          );

                          if (isEditMode) {
                            await TaskService.updateTask(task);
                          } else {
                            await TaskService.addTask(task);
                          }

                          await NotificationService.cancelReminder(
                            getNotificationId(task.id),
                          );

                          if (reminderDateTime != null) {
                            await NotificationService.scheduleTaskReminder(
                              id: getNotificationId(task.id),
                              title: task.title,
                              scheduledDate: reminderDateTime,
                            );
                          }

                          if (!mounted) return;

                          navigator.pop();
                          setState(() {});
                        },
                        child: Text(
                          isEditMode ? 'Update Task' : 'Save Task',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.25, duration: 350.ms).fadeIn();
          },
        );
      },
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TaskService.box.listenable(),
      builder: (context, Box<TaskModel> box, _) {
        final tasks = currentTab == BottomTab.home
            ? TaskService.getTodayTasks()
            : TaskService.getTasksByDate(selectedDate);
        final progress = getProgress(tasks);

        return Scaffold(
          body: SafeArea(
            child: currentTab == BottomTab.home
                ? buildHomeView(tasks, progress)
                : buildCalendarView(),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xff123B69),
            foregroundColor: Colors.white,
            onPressed: () {
              final date = currentTab == BottomTab.home
                  ? DateTime.now()
                  : selectedDate;
              openAddTaskSheet(taskDate: date);
            },
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
          ).animate().scale(duration: 300.ms),
          bottomNavigationBar: buildBottomNav(),
        );
      },
    );
  }

  Widget buildHomeView(List<TaskModel> tasks, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${getGreetingMessage()} ${getGreetingIcon()}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's Focus\n${tasks.length} tasks",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  height: 58,
                  width: 58,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xffF3C4BE),
                        color: const Color(0xff123B69),
                      );
                    },
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.12),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    currentTab = BottomTab.calendar;
                  });
                },
                child: const Text('Calendar'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No task today.\nTap + New Task to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                            task: task,
                            onToggle: () async {
                              await TaskService.updateTask(
                                task.copyWith(isDone: !task.isDone),
                              );
                            },
                            onEdit: () {
                              openAddTaskSheet(oldTask: task);
                            },
                            onDelete: () async {
                              await NotificationService.cancelReminder(
                                getNotificationId(task.id),
                              );
                              await TaskService.deleteTask(task.id);
                            },
                          )
                          .animate()
                          .fadeIn(delay: (index * 80).ms)
                          .slideY(begin: 0.18);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildCalendarView() {
    final allTasks = TaskService.getAllTasks();

    final selectedTasks = TaskService.getTasksByDate(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar<TaskModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            eventLoader: (day) {
              return allTasks.where((task) {
                return task.date.year == day.year &&
                    task.date.month == day.month &&
                    task.date.day == day.day;
              }).toList();
            },
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDate = selected;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xff123B69),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xff123B69).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks on ${DateFormat('MMM d').format(selectedDate)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: () => openAddTaskSheet(taskDate: selectedDate),
                icon: const Icon(Icons.add_circle),
              ),
            ],
          ),

          Expanded(
            child: selectedTasks.isEmpty
                ? const Center(
                    child: Text(
                      'No task for this date.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return TaskCard(
                            task: task,
                            onToggle: () async {
                              await TaskService.updateTask(
                                task.copyWith(isDone: !task.isDone),
                              );
                            },
                            onEdit: () {
                              openAddTaskSheet(oldTask: task);
                            },
                            onDelete: () async {
                              await NotificationService.cancelReminder(
                                getNotificationId(task.id),
                              );
                              await TaskService.deleteTask(task.id);
                            },
                          )
                          .animate()
                          .fadeIn(delay: (index * 70).ms)
                          .slideX(begin: 0.1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentTab == BottomTab.home ? 0 : 1,
      selectedItemColor: const Color(0xff123B69),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          currentTab = index == 0 ? BottomTab.home : BottomTab.calendar;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String createdTime = DateFormat('h:mm a').format(task.createdAt);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: task.isDone
              ? Colors.green.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(top: 3),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone ? const Color(0xff123B69) : Colors.white,
                  border: Border.all(
                    color: task.isDone
                        ? const Color(0xff123B69)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isDone ? Colors.grey : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.isPriority
                              ? Colors.amber.withValues(alpha: 0.35)
                              : Colors.grey.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.isPriority ? 'Priority' : task.category,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            createdTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      if (task.reminderTime != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('h:mm a').format(task.reminderTime!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
