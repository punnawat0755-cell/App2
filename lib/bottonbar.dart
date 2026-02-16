import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_application_1/module/chat/view/chat_view.dart';
import 'package:flutter_application_1/module/feed/view/feed_view.dart';
import 'package:flutter_application_1/module/home/view/home.dart';
import 'package:flutter_application_1/module/pet/view/pet_view.dart';
import 'package:flutter_application_1/module/profile/view/profile_view.dart';
import 'package:flutter_application_1/module/setting/view/edit.dart';
import 'package:flutter_application_1/module/setting/view/favorites.dart';
import 'package:flutter_application_1/module/setting/view/privacy.dart';
import 'package:flutter_application_1/module/setting/view/setting.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // ---------------------------------------------------------
  // 1. กำหนดรายการหน้าจอ (Pages) ที่นี่
  // เรียงลำดับตาม icon ใน Navigation Bar (0, 1, 2, 3, 4)
  // ---------------------------------------------------------
  final List<Widget> _pages = [
    // Index 0: หน้า Feed (ที่เราทำไว้)
    const FavoritesPage(),
    const PrivacyPage(),
    const EditProfilePage(),
    const SettingPage(),
    // const HomePage(),
    // const FeedPage(),
    const PetPage(),
    const ChatSelectionPage(),
    // const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ให้เนื้อหาไหลไปอยู่ใต้ Nav Bar
      // 2. ส่วน Body จะเปลี่ยนไปตามค่า _page ที่เลือก
      body: _pages[_page],

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(
            Icons.newspaper,
            size: 30,
            color: Color.fromARGB(255, 244, 244, 244),
          ),
          Icon(Icons.chat, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(Icons.pets, size: 30, color: Color.fromARGB(255, 244, 244, 244)),
          Icon(
            Icons.person,
            size: 30,
            color: Color.fromARGB(255, 244, 244, 244),
          ),
        ],
        color: Color(0xFF5CD9FF),
        buttonBackgroundColor: Color(0xFF5CD9FF),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _page = index; // อัปเดต index เพื่อเปลี่ยนหน้า
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
