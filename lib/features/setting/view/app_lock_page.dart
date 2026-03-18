import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key});

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  static const _lockEnabledKey = 'settings.app_lock_enabled';
  static const _lockOnResumeKey = 'settings.app_lock_on_resume';

  bool _isLoading = true;
  bool _lockEnabled = false;
  bool _lockOnResume = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
      _lockOnResume = prefs.getBool(_lockOnResumeKey) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, _lockEnabled);
    await prefs.setBool(_lockOnResumeKey, _lockOnResume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('App lock'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SwitchCard(
                  title: 'Enable app lock',
                  subtitle:
                      'Require an extra check before someone can enter the app.',
                  value: _lockEnabled,
                  onChanged: (value) async {
                    setState(() => _lockEnabled = value);
                    await _save();
                  },
                ),
                const SizedBox(height: 14),
                _SwitchCard(
                  title: 'Lock when app resumes',
                  subtitle:
                      'Ask for unlock again after the app returns from background.',
                  value: _lockOnResume,
                  onChanged: _lockEnabled
                      ? (value) async {
                          setState(() => _lockOnResume = value);
                          await _save();
                        }
                      : null,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E7F4)),
                  ),
                  child: const Text(
                    'This page stores lock preferences locally for now. If you want full biometric or PIN enforcement, we can wire that in next.',
                    style: TextStyle(
                      color: Color(0xFF5E6F81),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF17324D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6D7B8B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
