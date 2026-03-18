import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {
        'subject': 'How Are You support',
      },
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Help center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _FaqCard(
            question: 'How do I update my profile?',
            answer:
                'Open Settings, choose Edit profile, change the fields you want, then save.',
          ),
          const SizedBox(height: 14),
          const _FaqCard(
            question: 'Where can I change notification preferences?',
            answer:
                'Open Settings and go to Notifications to enable or disable reminders and chat alerts.',
          ),
          const SizedBox(height: 14),
          const _FaqCard(
            question: 'How do I change the app appearance?',
            answer:
                'Open Settings, choose Theme, then switch between system, light, or dark mode.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _openEmail(context),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Contact support'),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF17324D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              color: Color(0xFF5E6F81),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
