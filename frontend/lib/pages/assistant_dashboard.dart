import 'package:flutter/material.dart';

class AssistantDashboard extends StatefulWidget {
  const AssistantDashboard({super.key});

  @override
  _AssistantDashboardState createState() => _AssistantDashboardState();
}

class _AssistantDashboardState extends State<AssistantDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green[50],
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[50],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Jane Doe'),
                  SizedBox(width: 5),
                  Text('You’re on track for January, Jane!'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Achievements'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('News & Resources'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Community'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Rate Us'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            NetworkImage('https://via.placeholder.com/100'),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Jane Doe Watson',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '+ Premium',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Member since April 2024',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatIcon(Icons.female, 'Female • 16 year old'),
                      _buildStatIcon(Icons.local_fire_department, '7d'),
                      _buildStatIcon(Icons.flag, '85'),
                      _buildStatIcon(Icons.attach_money, '\$112'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Total Streak    Goals    Total Saved',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Invite Friend
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    'Invite Friend',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Get ${15} Free for a limited time',
                    style: TextStyle(color: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.green),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Streak Progress
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'You’re on your 3D streak!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Keep using the app to get benefits & bonus!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.grey[200],
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Chat Support
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.green),
                  const SizedBox(width: 10),
                  const Text(
                    'Need Help? Chat support live 24/7',
                    style: TextStyle(color: Colors.green),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.green),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 10),
      ],
    );
  }
}
