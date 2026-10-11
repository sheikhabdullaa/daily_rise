import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const bg = Color(0xFF101A17);
  static const surface = Color(0xFF192722);
  static const green = Color(0xFF91C7A2);
  static const cream = Color(0xFFF4F0E5);
  static const muted = Color(0xFF9BAEA3);
  static const border = Color(0xFF2B3C34);

  String _key(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Text(
            'Please sign in to view progress.',
            style: TextStyle(color: cream),
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .snapshots();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load progress. Please check your connection and Firestore permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cream, height: 1.5),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final now = DateTime.now();
            final todayKey = _key(now);

            final habits = docs.map((doc) {
              final data = doc.data();
              final dates =
                  (data['completedDates'] as List?)
                      ?.whereType<String>()
                      .toSet() ??
                  <String>{};

              return _ProgressHabit(
                title: (data['title'] ?? 'Untitled habit').toString(),
                completedDates: dates,
              );
            }).toList();

            final total = habits.length;
            final completedToday = habits
                .where((h) => h.completedDates.contains(todayKey))
                .length;

            final todayPercent = total == 0
                ? 0
                : (completedToday / total * 100).round();

            final weeklyData = List.generate(7, (index) {
              final date = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: 6 - index));

              final key = _key(date);
              final completed = habits
                  .where((habit) => habit.completedDates.contains(key))
                  .length;

              final percent = total == 0
                  ? 0.0
                  : (completed / total).clamp(0.0, 1.0).toDouble();

              return _DayProgress(
                date: date,
                completed: completed,
                percent: percent,
              );
            });

            final completedDayKeys = <String>{};
            for (final habit in habits) {
              completedDayKeys.addAll(habit.completedDates);
            }

            final streak = _calculateStreak(completedDayKeys, now);
            final activeDays = weeklyData
                .where((day) => day.completed > 0)
                .length;
            final weeklyAverage = weeklyData.isEmpty
                ? 0
                : (weeklyData.fold<double>(0, (sum, day) => sum + day.percent) /
                          7 *
                          100)
                      .round();

            final recent = <_RecentActivity>[];
            for (final habit in habits) {
              for (final key in habit.completedDates) {
                final date = DateTime.tryParse(key);
                if (date == null) continue;

                final normalized = DateTime(date.year, date.month, date.day);
                final today = DateTime(now.year, now.month, now.day);
                if (normalized.isAfter(today)) continue;

                recent.add(
                  _RecentActivity(title: habit.title, date: normalized),
                );
              }
            }

            recent.sort((a, b) => b.date.compareTo(a.date));

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
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
                        'Your Progress',
                        style: TextStyle(
                          color: cream,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Every small win moves you forward.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 23),

                      // Rhythm / streak card
                      Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: green,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CURRENT STREAK',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                      letterSpacing: 1.1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$streak ${streak == 1 ? 'day' : 'days'}',
                                    style: const TextStyle(
                                      color: cream,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Keep showing up for yourself.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Today',
                              value: '$completedToday/$total',
                              detail: '$todayPercent% complete',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard(
                              icon: Icons.calendar_month_rounded,
                              label: 'Active days',
                              value: '$activeDays/7',
                              detail: 'Last 7 days',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _statCard(
                        icon: Icons.insights_rounded,
                        label: 'Weekly consistency',
                        value: '$weeklyAverage%',
                        detail: 'Average daily completion',
                        fullWidth: true,
                      ),
                      const SizedBox(height: 27),

                      // Weekly chart
                      Container(
                        padding: const EdgeInsets.fromLTRB(17, 19, 17, 16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "This week's completion",
                              style: TextStyle(
                                color: cream,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Daily percentage of habits completed',
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 155,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: weeklyData.map((day) {
                                  final isToday = _key(day.date) == todayKey;
                                  final barHeight = 105 * day.percent;

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${(day.percent * 100).round()}%',
                                            style: TextStyle(
                                              color: isToday ? green : muted,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Container(
                                            height: barHeight < 4
                                                ? 4
                                                : barHeight,
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? green
                                                  : green.withValues(
                                                      alpha: 0.38,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            const [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S',
                                            ][day.date.weekday - 1],
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.circle, color: green, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'Completion today is highlighted',
                                  style: TextStyle(color: muted, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      const Text(
                        'Recent activity',
                        style: TextStyle(
                          color: cream,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 13),

                      if (recent.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: green,
                                size: 32,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No completed habits yet',
                                style: TextStyle(
                                  color: cream,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Complete a habit and your activity will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...recent.take(10).map((activity) {
                          final isToday = _key(activity.date) == todayKey;
                          final yesterday = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).subtract(const Duration(days: 1));
                          final isYesterday =
                              _key(activity.date) == _key(yesterday);

                          final dateLabel = isToday
                              ? 'Today'
                              : isYesterday
                              ? 'Yesterday'
                              : '${activity.date.day} ${_month(activity.date.month)}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: cream,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$dateLabel · Completed',
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: green,
                                  size: 19,
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

  int _calculateStreak(Set<String> completedDays, DateTime now) {
    if (completedDays.isEmpty) return 0;

    var day = DateTime(now.year, now.month, now.day);

    if (!completedDays.contains(_key(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    var count = 0;

    while (completedDays.contains(_key(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }

    return count;
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String detail,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: green, size: 23),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: cream,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHabit {
  final String title;
  final Set<String> completedDates;

  const _ProgressHabit({required this.title, required this.completedDates});
}

class _DayProgress {
  final DateTime date;
  final int completed;
  final double percent;

  const _DayProgress({
    required this.date,
    required this.completed,
    required this.percent,
  });
}

class _RecentActivity {
  final String title;
  final DateTime date;

  const _RecentActivity({required this.title, required this.date});
}
