import 'package:daily_rise/auth/authrepo.dart';
import 'package:daily_rise/screens/home_screen.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthRepo _authRepo = AuthRepo();

  bool _checking = false;
  bool _resending = false;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    try {
      // Refresh Firebase user's latest verification status.
      final user = await _authRepo.checkEmailVerified();

      if (!mounted) return;

      if (user) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showMessage(
          'Email is not verified yet. Open the verification link in your email first.',
        );
      }
    } catch (_) {
      _showMessage('Could not check verification. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _resending = true);

    try {
      final error = await _authRepo.resendVerificationEmail();

      if (!mounted) return;

      if (error == null) {
        _showMessage('A new verification link has been sent.');
      } else {
        _showMessage(error);
      }
    } catch (_) {
      _showMessage('Could not resend the email. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: forestBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: darkSurface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 55,
                        color: botanicalGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: warmCream,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'One small step before your DailyRise journey begins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: softSage,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: darkSurface,
                      borderRadius: BorderRadius.circular(18),
                      // border: Border.all(color: subtleBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: botanicalGreen,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Verification link sent to',
                          style: TextStyle(color: softSage, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: warmCream,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'What to do next',
                    style: TextStyle(
                      color: warmCream,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _instruction('1', 'Open your email inbox.'),
                  _instruction(
                    '2',
                    'Find the email from Firebase and open its verification link.',
                  ),
                  _instruction('3', 'Return here and tap the button below.'),

                  const SizedBox(height: 26),

                  ElevatedButton(
                    onPressed: _checking ? null : _checkVerification,
                    child: _checking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: forestBackground,
                            ),
                          )
                        : const Text("I've Verified — Continue"),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: (_resending || _checking)
                        ? null
                        : _resendVerification,
                    child: _resending
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: botanicalGreen,
                            ),
                          )
                        : const Text('Resend Verification Link'),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: (_checking || _resending)
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Back to Sign Up',
                      style: TextStyle(color: botanicalGreen),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Tip: If you cannot find the email, check your Spam or Junk folder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: softSage,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _instruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: forestGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: warmCream,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: softSage,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
