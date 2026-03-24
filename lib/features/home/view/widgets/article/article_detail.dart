import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String imagePath;
  final String content;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage = imagePath.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = constraints.maxWidth < 360
                ? scale.rs(14, min: 10, max: 14)
                : scale.rs(24, min: 16, max: 24);
            final imageHeight =
                (constraints.maxWidth * 0.62).clamp(190.0, 320.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: scale.rs(10, min: 8, max: 10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: scale.rs(10, min: 8, max: 10),
                          ),
                          child: Image.asset(
                            'assets/images/back.png',
                            width: scale.rs(25, min: 20, max: 25),
                            height: scale.rs(25, min: 20, max: 25),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(30, min: 20, max: 30)),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            scale.rs(24, min: 16, max: 24)),
                        child: SizedBox(
                          width: double.infinity,
                          height: imageHeight,
                          child: isNetworkImage
                              ? Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 14, max: 20)),
                      Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4489D7),
                            fontSize: scale.rf(20, min: 17, max: 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: scale.rs(20, min: 14, max: 20)),
                      Text(
                        content,
                        style: TextStyle(
                          color: const Color(0xFF4489D7),
                          fontSize: scale.rf(16, min: 14, max: 16),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: scale.rs(40, min: 28, max: 40)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
