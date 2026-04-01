import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/module/coin/controller/coin_controller.dart';
import 'package:flutter_application_1/module/home/view/home_view.dart';
import 'package:get/get.dart';

class CoinParticle {
  double top;
  double right;
  bool visible;
  CoinParticle({required this.top, required this.right, this.visible = false});
}

class CoinRewardScreen extends StatefulWidget {
  const CoinRewardScreen({Key? key}) : super(key: key);

  @override
  State<CoinRewardScreen> createState() => _CoinRewardScreenState();
}

class _CoinRewardScreenState extends State<CoinRewardScreen> {
  late final CoinController coinController;

  bool _isAnimating = false;
  final int _rewardCoins = 30;
  final int _totalFlyingCoins = 50;
  int _displayCoins = 0;

  List<CoinParticle> _particles = [];
  final Random _random = Random();
  final GlobalKey _targetCoinKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    coinController = Get.isRegistered<CoinController>()
        ? Get.find<CoinController>()
        : Get.put(CoinController(), permanent: true);
  }

  void _collectCoins() {
    if (_isAnimating) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_targetCoinKey.currentContext == null) return;

    final RenderBox targetBox =
        _targetCoinKey.currentContext!.findRenderObject() as RenderBox;
    final Offset targetGlobalPosition = targetBox.localToGlobal(Offset.zero);

    final targetCenterX = targetGlobalPosition.dx + (targetBox.size.width / 2);
    final targetCenterY = targetGlobalPosition.dy + (targetBox.size.height / 2);

    double endTopTarget = targetCenterY;
    double endRightTarget = screenWidth - targetCenterX;

    // จุดเริ่มต้นบิน ให้ยืดหยุ่นตามจอ
    double startTop = screenHeight * 0.75;
    double startRight = screenWidth * 0.45;

    setState(() {
      _isAnimating = true;
      _particles = List.generate(_totalFlyingCoins, (index) {
        return CoinParticle(top: startTop, right: startRight, visible: false);
      });
    });

    for (int i = 0; i < _totalFlyingCoins; i++) {
      Future.delayed(Duration(milliseconds: i * 30), () {
        if (!mounted) return;
        setState(() {
          _particles[i].visible = true;
          _particles[i].top = endTopTarget;
          _particles[i].right = endRightTarget;
        });
      });
    }

    int totalAnimTime = (_totalFlyingCoins * 30) + 1500;

    Future.delayed(Duration(milliseconds: totalAnimTime), () {
      if (!mounted) return;

      setState(() {
        _displayCoins = _rewardCoins;
        _particles.clear();
      });

      coinController.addCoins(_rewardCoins);

      Future.delayed(const Duration(milliseconds: 2200), () {
        Get.offAll(() => HomePage());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. ดึงขนาดหน้าจอมาคำนวณ Responsive
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 760; // เช็คว่าเป็นมือถือจอเล็กหรือไม่

    // 💡 2. ตั้งค่าตัวแปรแบบยืดหยุ่น
    final double paddingHorizontal = isSmallScreen ? 24.0 : 40.0;
    final double boxImageHeight = isSmallScreen ? 150.0 : 200.0;
    final double titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double buttonFontSize = isSmallScreen ? 16.0 : 18.0;
    final double spacingMiddle = isSmallScreen ? 30.0 : 50.0;
    final double buttonPaddingVertical = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF0CD),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- ป้ายจำนวนเหรียญรวม ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            key: _targetCoinKey,
                            height: isSmallScreen ? 20 : 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$_displayCoins",
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF634917),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // --- ป้ายบอกว่าได้กี่ Coin ---
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD348),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "คุณได้รับ Coin จำนวน $_rewardCoins Coin",
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF634917),
                      ),
                    ),
                  ),

                  SizedBox(height: spacingMiddle),

                  // --- กล่องสมบัติ ---
                  Image.asset(
                    'assets/images/coinbox.png',
                    height: boxImageHeight,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(flex: 2),

                  // --- ปุ่มเก็บเหรียญ ---
                  GestureDetector(
                    onTap: _collectCoins,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: buttonPaddingVertical,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFAE00),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/coin.png',
                            height: isSmallScreen ? 24 : 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "เก็บ Coin",
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF634917),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),

          // --- เลเยอร์เหรียญบิน ---
          ..._particles.map((particle) {
            final double flyingCoinSize = isSmallScreen ? 26.0 : 32.0;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutBack,
              top: particle.visible
                  ? (particle.top - flyingCoinSize / 2)
                  : (MediaQuery.of(context).size.height * 0.75),
              right: particle.visible
                  ? (particle.right - flyingCoinSize / 2)
                  : (MediaQuery.of(context).size.width * 0.45),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: particle.visible ? 1.0 : 0.0,
                child: Image.asset(
                  'assets/images/coin.png',
                  height: flyingCoinSize,
                  width: flyingCoinSize,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
