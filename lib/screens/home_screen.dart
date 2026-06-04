import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum BottomTab { home, calendar }

class _HomeScreenState extends State<HomeScreen> {
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

  double getProgress(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((task) => task.isDone).length;
    return done / tasks.length;
  }

  void openAddTaskSheet({DateTime? taskDate}) {
    titleController.clear();
    categoryController.clear();
    isPriority = false;

    final DateTime pickedDate = taskDate ?? selectedDate;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Task',
                    style: TextStyle(
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
                    decoration: inputDecoration('Task title'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: categoryController,
                    decoration: inputDecoration('Category e.g. Work, Study'),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    value: isPriority,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Priority task'),
                    activeColor: const Color(0xff123B69),
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
                        if (titleController.text.trim().isEmpty) return;

                        final task = TaskModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          category: categoryController.text.trim().isEmpty
                              ? 'Standard'
                              : categoryController.text.trim(),
                          date: pickedDate,
                          isPriority: isPriority,
                        );

                        await TaskService.addTask(task);

                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      child: const Text(
                        'Save Task',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
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
        final tasks = TaskService.getTasksByDate(selectedDate);
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
            onPressed: () => openAddTaskSheet(taskDate: selectedDate),
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
            'Good Morning,☀️',
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
                  color: Colors.black.withOpacity(0.08),
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
                DateFormat('EEEE, MMM d').format(selectedDate),
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
                        onDelete: () async {
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
                color: const Color(0xff123B69).withOpacity(0.3),
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
                        onDelete: () async {
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
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
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          color: task.isDone ? Colors.green.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 25,
                width: 25,
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
                    ? const Icon(Icons.check, color: Colors.white, size: 17)
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.isPriority
                              ? Colors.amber.withOpacity(0.35)
                              : Colors.grey.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.isPriority ? 'Priority' : task.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d').format(task.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}