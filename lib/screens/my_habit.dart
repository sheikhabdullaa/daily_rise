import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyHabitsScreen extends StatefulWidget {
  const MyHabitsScreen({super.key});

  @override
  State<MyHabitsScreen> createState() => _MyHabitsScreenState();
}

class _MyHabitsScreenState extends State<MyHabitsScreen> {
  static const bg = Color(0xFF101A17);
  static const surface = Color(0xFF192722);
  static const green = Color(0xFF91C7A2);
  static const cream = Color(0xFFF4F0E5);
  static const muted = Color(0xFF9BAEA3);
  static const border = Color(0xFF2B3C34);

  final user = FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get habitsRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits');
  }

  String get today {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addHabit() async {
    final ref = habitsRef;
    if (ref == null) {
      _message('Please sign in to add a habit.');
      return;
    }

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: const BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a new habit',
                    style: TextStyle(
                      color: cream,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: controller,
                    autofocus: false,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: cream),
                    decoration: InputDecoration(
                      hintText: 'e.g. Read 10 pages',
                      hintStyle: const TextStyle(color: muted),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: green),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a habit name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: bg,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(sheetContext, controller.text.trim());
                        }
                      },
                      child: const Text('Save habit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (title == null || title.trim().isEmpty) return;

    try {
      await ref.add({
        'title': title.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'completedDates': <String>[],
      });
    } catch (e) {
      _message('Could not save habit. Check your connection and permissions.');
    }
  }

  Future<void> _toggleHabit(String id, List<String> dates) async {
    final ref = habitsRef;
    if (ref == null) return;

    try {
      if (dates.contains(today)) {
        await ref.doc(id).update({
          'completedDates': FieldValue.arrayRemove([today]),
        });
      } else {
        await ref.doc(id).update({
          'completedDates': FieldValue.arrayUnion([today]),
        });
      }
    } catch (e) {
      _message('Could not update this habit.');
    }
  }

  Future<void> _deleteHabit(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Delete habit?', style: TextStyle(color: cream)),
        content: Text(
          'Delete "$title" and its completion history?',
          style: const TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await habitsRef?.doc(id).delete();
    } catch (e) {
      _message('Could not delete this habit.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final ref = habitsRef;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabit,
        backgroundColor: green,
        foregroundColor: bg,
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
      body: SafeArea(
        child: ref == null
            ? const Center(
                child: Text(
                  'Please sign in to view your habits.',
                  style: TextStyle(color: cream),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ref.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _centerMessage(
                      'Could not load habits.\nCheck your Firestore rules.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: green),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  docs.sort((a, b) {
                    final aTime = a.data()['createdAt'];
                    final bTime = b.data()['createdAt'];

                    if (aTime is Timestamp && bTime is Timestamp) {
                      return aTime.compareTo(bTime);
                    }
                    return 0;
                  });

                  final completed = docs.where((doc) {
                    final dates =
                        (doc.data()['completedDates'] as List?)
                            ?.whereType<String>()
                            .toList() ??
                        [];
                    return dates.contains(today);
                  }).length;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const Text(
                              'DAILYRISE',
                              style: TextStyle(
                                color: green,
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'My Habits',
                              style: TextStyle(
                                color: cream,
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'Build consistency, one day at a time.',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.all(19),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.track_changes_rounded,
                                    color: green,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$completed of ${docs.length} completed',
                                          style: const TextStyle(
                                            color: cream,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          "Today's progress",
                                          style: TextStyle(color: muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    docs.isEmpty
                                        ? '0%'
                                        : '${(completed / docs.length * 100).round()}%',
                                    style: const TextStyle(
                                      color: green,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Your routine',
                                    style: TextStyle(
                                      color: cream,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${docs.length} habits',
                                  style: const TextStyle(color: muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (docs.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: border),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.spa_outlined,
                                      color: green,
                                      size: 42,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'No habits yet',
                                      style: TextStyle(
                                        color: cream,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 7),
                                    Text(
                                      'Tap Add Habit to create your first routine.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: muted),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...docs.map((doc) {
                                final data = doc.data();
                                final title =
                                    (data['title'] ?? 'Untitled habit')
                                        .toString();
                                final dates =
                                    (data['completedDates'] as List?)
                                        ?.whereType<String>()
                                        .toList() ??
                                    [];
                                final isDone = dates.contains(today);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(19),
                                    border: Border.all(
                                      color: isDone
                                          ? green.withValues(alpha: 0.5)
                                          : border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _toggleHabit(doc.id, dates),
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          width: 27,
                                          height: 27,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? green
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDone ? green : muted,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isDone
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 17,
                                                  color: bg,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                color: isDone ? muted : cream,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                decoration: isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              isDone
                                                  ? 'Completed today'
                                                  : 'Keep your streak going',
                                              style: TextStyle(
                                                color: isDone ? green : muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        color: surface,
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          color: muted,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteHabit(doc.id, title);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Delete habit',
                                              style: TextStyle(color: cream),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _centerMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: cream, height: 1.5),
        ),
      ),
    );
  }
}
