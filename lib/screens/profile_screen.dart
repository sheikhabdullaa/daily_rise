// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class ProfileSettingsScreen extends StatefulWidget {
//   const ProfileSettingsScreen({super.key});

//   @override
//   State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
// }

// class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
//   static const Color bg = Color(0xFF101A17);
//   static const Color surface = Color(0xFF192722);
//   static const Color green = Color(0xFF91C7A2);
//   static const Color cream = Color(0xFFF4F0E5);
//   static const Color muted = Color(0xFF9BAEA3);
//   static const Color border = Color(0xFF2B3C34);
//   static const Color danger = Color(0xFFFF8A80);

//   bool _loadingSettings = true;
//   bool _darkMode = true;
//   bool _remindersEnabled = true;
//   String _reminderTime = '07:30 AM';
//   bool _saving = false;

//   User? get _user => FirebaseAuth.instance.currentUser;

//   DocumentReference<Map<String, dynamic>>? get _userDocument {
//     final uid = _user?.uid;
//     if (uid == null) return null;

//     return FirebaseFirestore.instance.collection('users').doc(uid);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadSettings();
//   }

//   Future<void> _loadSettings() async {
//     try {
//       final ref = _userDocument;
//       if (ref == null) {
//         if (mounted) setState(() => _loadingSettings = false);
//         return;
//       }

//       final snapshot = await ref.get();
//       final data = snapshot.data() ?? {};
//       final settings = data['settings'] is Map
//           ? Map<String, dynamic>.from(data['settings'] as Map)
//           : <String, dynamic>{};

//       if (!mounted) return;

//       setState(() {
//         _darkMode = settings['darkMode'] as bool? ?? true;
//         _remindersEnabled = settings['remindersEnabled'] as bool? ?? true;
//         _reminderTime = settings['reminderTime'] as String? ?? '07:30 AM';
//         _loadingSettings = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _loadingSettings = false);
//       _message('Could not load saved preferences.');
//     }
//   }

//   Future<void> _saveSettings({
//     bool? darkMode,
//     bool? remindersEnabled,
//     String? reminderTime,
//   }) async {
//     final ref = _userDocument;
//     if (ref == null) {
//       _message('Please sign in first.');
//       return;
//     }

//     final previousDark = _darkMode;
//     final previousReminder = _remindersEnabled;
//     final previousTime = _reminderTime;

//     setState(() {
//       if (darkMode != null) _darkMode = darkMode;
//       if (remindersEnabled != null) {
//         _remindersEnabled = remindersEnabled;
//       }
//       if (reminderTime != null) _reminderTime = reminderTime;
//       _saving = true;
//     });

//     try {
//       await ref.set({
//         'settings': {
//           'darkMode': _darkMode,
//           'remindersEnabled': _remindersEnabled,
//           'reminderTime': _reminderTime,
//         },
//       }, SetOptions(merge: true));
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         _darkMode = previousDark;
//         _remindersEnabled = previousReminder;
//         _reminderTime = previousTime;
//       });

//       _message('Could not save settings. Check Firestore permissions.');
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   void _message(String text) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(text),
//           backgroundColor: surface,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }

//   String get _displayName {
//     final name = _user?.displayName?.trim();
//     if (name != null && name.isNotEmpty) return name;

//     final email = _user?.email;
//     if (email != null && email.contains('@')) {
//       return email.split('@').first;
//     }

//     return 'DailyRise User';
//   }

//   String get _initials {
//     final parts = _displayName
//         .trim()
//         .split(RegExp(r'\s+'))
//         .where((part) => part.isNotEmpty)
//         .toList();

//     if (parts.isEmpty) return 'D';
//     if (parts.length == 1) return parts.first[0].toUpperCase();

//     return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
//   }

//   Future<void> _editDisplayName() async {
//     final user = _user;
//     if (user == null) return;

//     final controller = TextEditingController(text: user.displayName ?? '');

//     final name = await showDialog<String>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: surface,
//         title: const Text('Edit your name', style: TextStyle(color: cream)),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           maxLength: 60,
//           textCapitalization: TextCapitalization.words,
//           style: const TextStyle(color: cream),
//           decoration: InputDecoration(
//             hintText: 'Your name',
//             hintStyle: const TextStyle(color: muted),
//             enabledBorder: const UnderlineInputBorder(
//               borderSide: BorderSide(color: border),
//             ),
//             focusedBorder: const UnderlineInputBorder(
//               borderSide: BorderSide(color: green),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () =>
//                 Navigator.pop(dialogContext, controller.text.trim()),
//             child: const Text('Save', style: TextStyle(color: green)),
//           ),
//         ],
//       ),
//     );

//     controller.dispose();

//     if (name == null || name.isEmpty) return;

//     try {
//       await user.updateDisplayName(name);
//       await user.reload();
//       if (!mounted) return;
//       setState(() {});
//       _message('Profile name updated.');
//     } catch (_) {
//       _message('Could not update your name.');
//     }
//   }

//   Future<void> _changePassword() async {
//     final email = _user?.email;

//     if (email == null || email.isEmpty) {
//       _message('No email address is associated with this account.');
//       return;
//     }

//     final send = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: surface,
//         title: const Text('Reset password', style: TextStyle(color: cream)),
//         content: Text(
//           'Send a password reset link to $email?',
//           style: const TextStyle(color: muted, height: 1.5),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             child: const Text('Send link', style: TextStyle(color: green)),
//           ),
//         ],
//       ),
//     );

//     if (send != true) return;

//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       _message('Password reset email sent. Check your inbox.');
//     } on FirebaseAuthException catch (e) {
//       _message(e.message ?? 'Could not send password reset email.');
//     } catch (_) {
//       _message('Could not send password reset email.');
//     }
//   }

//   Future<void> _selectReminderTime() async {
//     final parsed = _parseReminderTime(_reminderTime);

//     final picked = await showTimePicker(
//       context: context,
//       initialTime: parsed,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.dark(
//               primary: green,
//               surface: surface,
//               onSurface: cream,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked == null) return;

//     final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
//     final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
//     final formatted =
//         '$hour:${picked.minute.toString().padLeft(2, '0')} $period';

//     await _saveSettings(reminderTime: formatted);
//   }

//   TimeOfDay _parseReminderTime(String value) {
//     try {
//       final parts = value.split(' ');
//       final time = parts[0].split(':');
//       var hour = int.parse(time[0]);
//       final minute = int.parse(time[1]);

//       if (parts.length > 1 && parts[1] == 'PM' && hour != 12) {
//         hour += 12;
//       }
//       if (parts.length > 1 && parts[1] == 'AM' && hour == 12) {
//         hour = 0;
//       }

//       return TimeOfDay(hour: hour, minute: minute);
//     } catch (_) {
//       return const TimeOfDay(hour: 7, minute: 30);
//     }
//   }

//   Future<void> _exportHabitData() async {
//     final uid = _user?.uid;
//     if (uid == null) return;

//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('habits')
//           .get();

//       final habits = snapshot.docs.map((doc) {
//         final data = doc.data();
//         final createdAt = data['createdAt'];

//         return {
//           'id': doc.id,
//           'title': data['title'] ?? '',
//           'createdAt': createdAt is Timestamp
//               ? createdAt.toDate().toIso8601String()
//               : null,
//           'completedDates': data['completedDates'] ?? <String>[],
//         };
//       }).toList();

//       final jsonText = const JsonEncoder.withIndent('  ').convert({
//         'exportedAt': DateTime.now().toIso8601String(),
//         'user': {
//           'uid': uid,
//           'email': _user?.email,
//           'displayName': _user?.displayName,
//         },
//         'habits': habits,
//       });

//       if (!mounted) return;

//       await showDialog<void>(
//         context: context,
//         builder: (dialogContext) => AlertDialog(
//           backgroundColor: surface,
//           title: const Text(
//             'Habit data export',
//             style: TextStyle(color: cream),
//           ),
//           content: SizedBox(
//             width: 420,
//             child: SingleChildScrollView(
//               child: SelectableText(
//                 jsonText,
//                 style: const TextStyle(color: muted, fontSize: 11, height: 1.5),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 await Clipboard.setData(ClipboardData(text: jsonText));
//                 if (!dialogContext.mounted) return;
//                 Navigator.pop(dialogContext);
//                 _message('Export JSON copied to clipboard.');
//               },
//               child: const Text('Copy JSON', style: TextStyle(color: green)),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       );
//     } catch (_) {
//       _message('Could not export habit data. Check Firestore permissions.');
//     }
//   }

//   Future<void> _showPrivacyInfo() async {
//     await showDialog<void>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: surface,
//         title: const Text('Privacy & Terms', style: TextStyle(color: cream)),
//         content: const SingleChildScrollView(
//           child: Text(
//             'DailyRise stores your account information and habit records '
//             'using Firebase services configured by the app owner.\n\n'
//             'Your habit completion dates are used to calculate progress '
//             'and streaks. Protect your account credentials and sign out '
//             'when using a shared device.\n\n'
//             'This is an in-app information screen, not a published legal '
//             'privacy policy. Add your actual privacy policy URL and terms '
//             'before publishing the app.',
//             style: TextStyle(color: muted, height: 1.6, fontSize: 13),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Close', style: TextStyle(color: green)),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _signOut() async {
//     final confirm = await _confirm(
//       title: 'Sign out of DailyRise?',
//       message: 'You can sign in again whenever you want.',
//       action: 'Sign out',
//     );

//     if (confirm != true) return;

//     try {
//       await FirebaseAuth.instance.signOut();
//       if (!mounted) return;
//       _message('Signed out successfully.');
//     } on FirebaseAuthException catch (e) {
//       _message(e.message ?? 'Could not sign out.');
//     } catch (_) {
//       _message('Could not sign out.');
//     }
//   }

//   Future<void> _deleteAccount() async {
//     final user = _user;
//     if (user == null) return;

//     final confirm = await _confirm(
//       title: 'Delete account?',
//       message:
//           'This permanently deletes your Firebase Authentication account. '
//           'Your Firestore habit records may need separate cleanup. '
//           'This action cannot be undone.',
//       action: 'Delete account',
//       destructive: true,
//     );

//     if (confirm != true) return;

//     try {
//       await user.delete();
//       if (!mounted) return;
//       _message('Account deleted.');
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'requires-recent-login') {
//         _message('For security, sign in again before deleting your account.');
//       } else {
//         _message(e.message ?? 'Could not delete account.');
//       }
//     } catch (_) {
//       _message('Could not delete account.');
//     }
//   }

//   Future<bool?> _confirm({
//     required String title,
//     required String message,
//     required String action,
//     bool destructive = false,
//   }) {
//     return showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: surface,
//         title: Text(title, style: const TextStyle(color: cream)),
//         content: Text(
//           message,
//           style: const TextStyle(color: muted, height: 1.5, fontSize: 13),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Cancel', style: TextStyle(color: muted)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             child: Text(
//               action,
//               style: TextStyle(color: destructive ? danger : green),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = _user;

//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: _loadingSettings
//             ? const Center(child: CircularProgressIndicator(color: green))
//             : CustomScrollView(
//                 slivers: [
//                   SliverPadding(
//                     padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
//                     sliver: SliverList(
//                       delegate: SliverChildListDelegate([
//                         Row(
//                           children: [
//                             const Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'DAILYRISE',
//                                     style: TextStyle(
//                                       color: green,
//                                       fontSize: 10,
//                                       letterSpacing: 2,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'Profile & Settings',
//                                     style: TextStyle(
//                                       color: cream,
//                                       fontSize: 27,
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             if (_saving)
//                               const SizedBox(
//                                 width: 18,
//                                 height: 18,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: green,
//                                 ),
//                               ),
//                           ],
//                         ),
//                         const SizedBox(height: 22),

//                         // Profile card
//                         Container(
//                           padding: const EdgeInsets.all(19),
//                           decoration: BoxDecoration(
//                             color: surface,
//                             borderRadius: BorderRadius.circular(22),
//                             border: Border.all(color: border),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   color: green.withValues(alpha: 0.15),
//                                   shape: BoxShape.circle,
//                                   border: Border.all(
//                                     color: green.withValues(alpha: 0.3),
//                                   ),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     _initials,
//                                     style: const TextStyle(
//                                       color: green,
//                                       fontSize: 21,
//                                       fontWeight: FontWeight.w800,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 14),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       user?.displayName?.trim().isNotEmpty ==
//                                               true
//                                           ? user!.displayName!
//                                           : _displayName,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(
//                                         color: cream,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 5),
//                                     Text(
//                                       user?.email ?? 'No email available',
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(
//                                         color: muted,
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 7),
//                                     Row(
//                                       children: [
//                                         const Icon(
//                                           Icons.verified_user_rounded,
//                                           color: green,
//                                           size: 13,
//                                         ),
//                                         const SizedBox(width: 5),
//                                         Text(
//                                           user?.emailVerified == true
//                                               ? 'Email verified'
//                                               : 'Firebase account',
//                                           style: const TextStyle(
//                                             color: green,
//                                             fontSize: 10,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               IconButton(
//                                 tooltip: 'Edit name',
//                                 onPressed: _editDisplayName,
//                                 icon: const Icon(
//                                   Icons.edit_outlined,
//                                   color: green,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 26),

//                         _sectionLabel('APP PREFERENCES'),
//                         const SizedBox(height: 12),
//                         _settingsCard(
//                           children: [
//                             _settingsRow(
//                               icon: Icons.dark_mode_outlined,
//                               title: 'Appearance',
//                               subtitle: _darkMode
//                                   ? 'Dark theme selected'
//                                   : 'Light preference selected',
//                               trailing: Switch(
//                                 value: _darkMode,
//                                 activeThumbColor: green,
//                                 onChanged: (value) =>
//                                     _saveSettings(darkMode: value),
//                               ),
//                               onTap: () => _saveSettings(darkMode: !_darkMode),
//                             ),
//                             _rowDivider(),
//                             _settingsRow(
//                               icon: Icons.notifications_active_outlined,
//                               title: 'Daily reminders',
//                               subtitle: _remindersEnabled
//                                   ? 'Reminder preference is on'
//                                   : 'Reminder preference is off',
//                               trailing: Switch(
//                                 value: _remindersEnabled,
//                                 activeThumbColor: green,
//                                 onChanged: (value) =>
//                                     _saveSettings(remindersEnabled: value),
//                               ),
//                               onTap: () => _saveSettings(
//                                 remindersEnabled: !_remindersEnabled,
//                               ),
//                             ),
//                             _rowDivider(),
//                             _settingsRow(
//                               icon: Icons.access_time_rounded,
//                               title: 'Reminder time',
//                               subtitle: _reminderTime,
//                               trailing: const Icon(
//                                 Icons.chevron_right_rounded,
//                                 color: muted,
//                               ),
//                               onTap: _selectReminderTime,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 25),

//                         _sectionLabel('ACCOUNT & SECURITY'),
//                         const SizedBox(height: 12),
//                         _settingsCard(
//                           children: [
//                             _settingsRow(
//                               icon: Icons.lock_outline_rounded,
//                               title: 'Change password',
//                               subtitle: 'Receive a password reset email',
//                               trailing: const Icon(
//                                 Icons.chevron_right_rounded,
//                                 color: muted,
//                               ),
//                               onTap: _changePassword,
//                             ),
//                             _rowDivider(),
//                             _settingsRow(
//                               icon: Icons.privacy_tip_outlined,
//                               title: 'Privacy & Terms',
//                               subtitle: 'Learn how your data is used',
//                               trailing: const Icon(
//                                 Icons.open_in_new_rounded,
//                                 color: muted,
//                                 size: 17,
//                               ),
//                               onTap: _showPrivacyInfo,
//                             ),
//                             _rowDivider(),
//                             _settingsRow(
//                               icon: Icons.file_download_outlined,
//                               title: 'Export habit data',
//                               subtitle: 'View and copy your data as JSON',
//                               trailing: const Icon(
//                                 Icons.chevron_right_rounded,
//                                 color: muted,
//                               ),
//                               onTap: _exportHabitData,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 27),

//                         SizedBox(
//                           width: double.infinity,
//                           child: OutlinedButton.icon(
//                             onPressed: _signOut,
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: cream,
//                               backgroundColor: surface,
//                               side: const BorderSide(color: border),
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                             ),
//                             icon: const Icon(Icons.logout_rounded, size: 18),
//                             label: const Text(
//                               'Sign Out of DailyRise',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         SizedBox(
//                           width: double.infinity,
//                           child: FilledButton.icon(
//                             onPressed: _deleteAccount,
//                             style: FilledButton.styleFrom(
//                               backgroundColor: const Color(0xFF291714),
//                               foregroundColor: danger,
//                               padding: const EdgeInsets.symmetric(vertical: 15),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                             ),
//                             icon: const Icon(
//                               Icons.delete_outline_rounded,
//                               size: 18,
//                             ),
//                             label: const Text('Delete Account'),
//                           ),
//                         ),
//                         const SizedBox(height: 25),
//                         const Center(
//                           child: Column(
//                             children: [
//                               Icon(Icons.spa_rounded, color: green, size: 22),
//                               SizedBox(height: 7),
//                               Text(
//                                 'DailyRise · Build better every day',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(color: muted, fontSize: 11),
//                               ),
//                               SizedBox(height: 5),
//                               Text(
//                                 'Personal growth, one day at a time.',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(color: muted, fontSize: 10),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ]),
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _sectionLabel(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         color: green,
//         fontSize: 10,
//         letterSpacing: 1.5,
//         fontWeight: FontWeight.w800,
//       ),
//     );
//   }

//   Widget _settingsCard({required List<Widget> children}) {
//     return Container(
//       decoration: BoxDecoration(
//         color: surface,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: border),
//       ),
//       child: Column(children: children),
//     );
//   }

//   Widget _rowDivider() {
//     return const Padding(
//       padding: EdgeInsets.only(left: 57),
//       child: Divider(color: border, height: 1, thickness: 0.7),
//     );
//   }

//   Widget _settingsRow({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Widget trailing,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
//           child: Row(
//             children: [
//               Container(
//                 width: 34,
//                 height: 34,
//                 decoration: BoxDecoration(
//                   color: green.withValues(alpha: 0.10),
//                   borderRadius: BorderRadius.circular(11),
//                 ),
//                 child: Icon(icon, color: green, size: 19),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         color: cream,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: const TextStyle(
//                         color: muted,
//                         fontSize: 10,
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               trailing,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
