// lib/login_page.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _Stage { enterPhone, enterOtp }

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  _Stage _stage = _Stage.enterPhone;
  bool _loading = false;
  String? _error;
  int _resendRemaining = 0;
  Timer? _resendTimer;

  // call this when you enter OTP stage or after a resend
  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendRemaining <= 1) {
        t.cancel();
        setState(() => _resendRemaining = 0);
      } else {
        setState(() => _resendRemaining -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.instance.sendOtp(phone);
      setState(() {
        _stage = _Stage.enterOtp;
      });
      _startResendTimer();
      sleep(Duration(seconds: 1));
    } catch (e) {
      setState(() {
        _error = 'ارسال کد با خطا مواجه شد';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.instance.verifyOtp(phone, otp);
      // pop back to HomePage—drawer now sees ApiService.isLoggedIn==true
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'کد نامعتبر یا منقضی شد';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOtpStage = _stage == _Stage.enterOtp;
    return Scaffold(
      appBar: AppBar(title: const Text('ورود / ثبت‌نام'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isOtpStage) ...[
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'شماره موبایل',
                  hintText: '+989123456789',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: _loading ? null : _sendOtp,
                child:
                    _loading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'ارسال کد',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ] else ...[
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'کد دریافتی',
                  hintText: '۴ رقمی',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                child:
                    _loading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('تأیید کد'),
              ),
              const SizedBox(height: 8),

              // Resend button
              TextButton(
                onPressed:
                    _resendRemaining == 0 && !_loading
                        ? () async {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            await ApiService.instance.resendOtp(
                              _phoneCtrl.text.trim(),
                            );
                            _startResendTimer();
                          } catch (e) {
                            setState(() => _error = 'ارسال مجدد ناموفق بود');
                          } finally {
                            setState(() => _loading = false);
                          }
                        }
                        : null,
                child: Text(
                  _resendRemaining > 0
                      ? 'ارسال مجدد کد ($_resendRemaining)'
                      : 'ارسال مجدد کد',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
