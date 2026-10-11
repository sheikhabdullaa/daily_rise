import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _background = Color(0xFF101A17);
  static const Color _surface = Color(0xFF192722);
  static const Color _green = Color(0xFF91C7A2);
  static const Color _cream = Color(0xFFF4F0E5);
  static const Color _muted = Color(0xFF9BAEA3);
  static const Color _border = Color(0xFF2B3C34);

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _habitsCollection {
    final user = _user;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('habits');
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _displayName {
    final user = _user;
    final name = user?.displayName?.trim();

    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final collection = _habitsCollection;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: collection == null
            ? _buildSignedOutState()
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: collection.orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      'Could not load your habits.',
                      onRetry: () {
                        setState(() {});
                      },
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _green),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  return _buildDashboard(
                    documents: documents,
                    collection: collection,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDashboard({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    required CollectionReference<Map<String, dynamic>> collection,
  }) {
    final habits = documents.map((doc) {
      return _HabitData(
        id: doc.id,
        title: (doc.data()['title'] ?? 'Untitled habit').toString(),
        completedDates: _readCompletedDates(doc.data()['completedDates']),
      );
    }).toList();

    final completedToday = habits
        .where((habit) => habit.completedDates.contains(_todayKey))
        .length;

    final total = habits.length;
    final progress = total == 0 ? 0.0 : completedToday / total;
    final streak = _calculateStreak(habits);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(),
              const SizedBox(height: 28),
              _buildWelcomeCard(
                completedToday: completedToday,
                total: total,
                progress: progress,
              ),
              const SizedBox(height: 16),
              _buildStats(streak: streak, total: total),
              const SizedBox(height: 30),
              _buildHabitsHeader(total: total),
              const SizedBox(height: 14),
            ]),
          ),
        ),
        if (habits.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: _buildEmptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final habit = habits[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHabitCard(habit: habit, collection: collection),
                );
              }, childCount: habits.length),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverToBoxAdapter(child: _buildQuoteCard()),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.spa_rounded, color: _green, size: 25),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DailyRise',
                style: TextStyle(
                  color: _cream,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'BUILD BETTER EVERY DAY',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: IconButton(
            tooltip: 'Sign out',
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded, color: _muted, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard({
    required int completedToday,
    required int total,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting, style: const TextStyle(color: _muted, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            '$_displayName 👋',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _cream,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Small steps today, big changes tomorrow.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  "Today's progress",
                  style: TextStyle(
                    color: _cream,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completedToday/$total completed',
                style: const TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: _background,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? 'Add your first habit to start your journey.'
                : progress == 1
                ? 'Amazing! You completed all your habits today.'
                : 'Keep going. Every completed habit counts.',
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStats({required int streak, required int total}) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_rounded,
            value: '$streak',
            label: 'Day streak',
            iconColor: const Color(0xFFFFB36B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.track_changes_rounded,
            value: '$total',
            label: 'Total habits',
            iconColor: _green,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsHeader({required int total}) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your habits',
                style: TextStyle(
                  color: _cream,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Consistency is the key to growth.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _showAddHabitSheet,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: _background,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text(
            'Add habit',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard({
    required _HabitData habit,
    required CollectionReference<Map<String, dynamic>> collection,
  }) {
    final completed = habit.completedDates.contains(_todayKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: completed ? _green.withValues(alpha: 0.45) : _border,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => _toggleHabit(habit, collection),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 27,
              width: 27,
              decoration: BoxDecoration(
                color: completed ? _green : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed ? _green : _muted,
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: _background,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: completed ? _muted : _cream,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  completed ? 'Completed today' : 'Keep up the good work',
                  style: TextStyle(
                    color: completed ? _green : _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Habit options',
            color: _surface,
            icon: const Icon(Icons.more_horiz_rounded, color: _muted),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteHabit(habit, collection);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF8A80),
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Text('Delete habit', style: TextStyle(color: _cream)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.spa_outlined, color: _green, size: 45),
          SizedBox(height: 14),
          Text(
            'Start with one small habit',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _cream,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a habit and build a routine that works for you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green.withValues(alpha: 0.20)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: _green, size: 29),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You do not rise to the level of your goals. '
                  'You fall to the level of your systems.',
                  style: TextStyle(
                    color: _cream,
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BUILD YOUR SYSTEM, ONE DAY AT A TIME',
                  style: TextStyle(
                    color: _green,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, color: _green, size: 48),
            const SizedBox(height: 14),
            const Text(
              'You are not signed in',
              style: TextStyle(
                color: _cream,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to access your habits.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Refresh session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _cream, fontSize: 15),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddHabitSheet() async {
    final collection = _habitsCollection;

    if (collection == null) {
      _showMessage('Please sign in first.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return _AddHabitSheet(
          onSave: (title) async {
            await collection.add({
              'title': title,
              'createdAt': FieldValue.serverTimestamp(),
              'completedDates': <String>[],
            });
          },
        );
      },
    );
  }

  Future<void> _toggleHabit(
    _HabitData habit,
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final doc = collection.doc(habit.id);
    final completed = habit.completedDates.contains(_todayKey);

    try {
      if (completed) {
        await doc.update({
          'completedDates': FieldValue.arrayRemove([_todayKey]),
        });
      } else {
        await doc.update({
          'completedDates': FieldValue.arrayUnion([_todayKey]),
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not update habit. Please try again.');
    }
  }

  Future<void> _confirmDeleteHabit(
    _HabitData habit,
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text('Delete habit?', style: TextStyle(color: _cream)),
          content: Text(
            'Are you sure you want to delete "${habit.title}"?',
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFFF8A80)),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await collection.doc(habit.id).delete();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not delete habit. Please try again.');
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text('Sign out?', style: TextStyle(color: _cream)),
          content: const Text(
            'Do you want to sign out of DailyRise?',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign out', style: TextStyle(color: _green)),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (error) {
        if (!mounted) return;
        _showMessage('Could not sign out. Please try again.');
      }
    }
  }

  List<String> _readCompletedDates(dynamic value) {
    if (value is! List) return <String>[];

    return value.whereType<String>().toSet().toList();
  }

  int _calculateStreak(List<_HabitData> habits) {
    if (habits.isEmpty) return 0;

    final completedDays = <String>{};

    for (final habit in habits) {
      completedDays.addAll(habit.completedDates);
    }

    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);

    String keyFor(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    // Allow a streak to continue if today's habits have not been
    // completed yet, but yesterday had activity.
    if (!completedDays.contains(keyFor(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    var streak = 0;

    while (completedDays.contains(keyFor(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surface,
        ),
      );
  }
}

class _HabitData {
  final String id;
  final String title;
  final List<String> completedDates;

  const _HabitData({
    required this.id,
    required this.title,
    required this.completedDates,
  });
}

class _AddHabitSheet extends StatefulWidget {
  final Future<void> Function(String title) onSave;

  const _AddHabitSheet({required this.onSave});

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  static const Color _background = Color(0xFF101A17);
  static const Color _surface = Color(0xFF192722);
  static const Color _green = Color(0xFF91C7A2);
  static const Color _cream = Color(0xFFF4F0E5);
  static const Color _muted = Color(0xFF9BAEA3);
  static const Color _border = Color(0xFF2B3C34);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    final title = _controller.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorText = 'Please enter a habit name.';
      });
      return;
    }

    if (title.length > 80) {
      setState(() {
        _errorText = 'Habit name must be 80 characters or less.';
      });
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onSave(title);

      if (!mounted) return;

      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorText = 'Could not save habit. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: _border),
                    left: BorderSide(color: _border),
                    right: BorderSide(color: _border),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create a new habit',
                      style: TextStyle(
                        color: _cream,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start small. Stay consistent. Grow every day.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HABIT NAME',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: false,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isSaving) _saveHabit();
                      },
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                      style: const TextStyle(color: _cream, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Read for 15 minutes',
                        hintStyle: const TextStyle(color: _muted, fontSize: 14),
                        counterStyle: const TextStyle(color: _muted),
                        errorText: _errorText,
                        filled: true,
                        fillColor: _surface,
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          color: _green,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 17,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _green,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveHabit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          disabledBackgroundColor: _green.withValues(
                            alpha: 0.5,
                          ),
                          foregroundColor: _background,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 21,
                                width: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _background,
                                ),
                              )
                            : const Text(
                                'Save habit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
