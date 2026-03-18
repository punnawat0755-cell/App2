import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('About app'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _InfoCard(
            title: 'How Are You',
            subtitle: 'Version 1.0.0+1',
            icon: Icons.favorite_outline_rounded,
          ),
          SizedBox(height: 14),
          _TextCard(
            title: 'Purpose',
            body:
                'This app is designed to support daily emotional check-ins, guided conversations, and personal wellbeing tracking in one place.',
          ),
          SizedBox(height: 14),
          _TextCard(
            title: 'What is included',
            body:
                'You can use the app for mood check-ins, chat flows, profile customization, and basic personalization settings.',
          ),
          SizedBox(height: 14),
          _TextCard(
            title: 'Privacy note',
            body:
                'Settings shown in this version focus on client-side controls and profile preferences. For any policy questions, check the Privacy and Help sections.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F4)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2A6EBB)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17324D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6D7B8B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

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
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17324D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
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
