import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/core/services/entry_flow_guard.dart';
import 'package:flutter_application_1/features/home/model/home_video_clip.dart';
import 'package:flutter_application_1/features/home/service/home_video_prefetch_service.dart';
import 'package:flutter_application_1/features/home/service/home_video_repository.dart';
import 'package:flutter_application_1/features/home/view/daily_mood_page.dart';
import 'package:flutter_application_1/features/home/view/play_video_page.dart';
import 'package:flutter_application_1/features/home/view/video_preview_controller_factory.dart';
import 'package:flutter_application_1/features/home/view/video_capture_page.dart';
import 'package:flutter_application_1/features/home/view/widgets/article/article_card.dart';
import 'package:flutter_application_1/features/home/view/widgets/article/article_detail.dart';
import 'package:flutter_application_1/features/home/view/widgets/home_widgets.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/setting/view/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _defaultMissionDays = 138;

  int _currentBannerIndex = 0;
  late final PageController _pageController;
  late final Stream<List<HomeVideoClip>> _videoClipsStream;
  Timer? _timer;
  final HomeVideoRepository _homeVideoRepository = HomeVideoRepository();
  final HomeVideoPrefetchService _homeVideoPrefetchService =
      HomeVideoPrefetchService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isNameLoading = true;
  bool _isUploadingClip = false;
  String _displayName = 'ผู้ใช้';
  String _lastWarmupSignature = '';

  final List<_HomeArticle> _articleList = const [
    _HomeArticle(
      title: 'วาฬ 52Hz\nไม่ได้อยู่คนเดียว',
      subtitle: '1 Month Ago',
      imagePath: 'assets/images/article1.png',
      detailImagePath: 'assets/images/article1.png',
      detailTitle: 'วาฬ 52Hz ไม่ได้อยู่คนเดียว',
      content: '''
เคยถูกใช้เป็นภาพสะท้อนความเหงาที่รุนแรงที่สุดของมนุษย์ เรามักฉายภาพความกลัวการถูกทอดทิ้งและความรู้สึกแปลกแยกของตัวเองลงไปที่มัน จนกลายเป็นสัญลักษณ์ของการ "มีเสียงที่ไม่มีใครได้ยิน"

แต่ในทางจิตวิทยา เมื่อวิทยาศาสตร์เริ่มค้นพบว่ามันอาจไม่ได้อยู่ลำพัง และอาจมีวาฬตัวอื่นที่ใช้คลื่นความถี่นี้เช่นกัน การตีความจึงเปลี่ยนไปอย่างสิ้นเชิง จากเดิมที่เป็นโศกนาฏกรรมของความโดดเดี่ยว กลายมาเป็นบทเรียนสำคัญเรื่อง "ความแตกต่างของการสื่อสาร" (Communication Differences)

การที่มันส่งเสียงในคลื่นความถี่ที่ไม่เหมือนใครไม่ได้หมายความว่ามันบกพร่อง หรือไร้ค่า แต่อาจเป็นเพียงการแสดงออกถึงตัวตนที่แท้จริงในรูปแบบเฉพาะทาง ซึ่งสะท้อนให้เห็นว่าในสังคมมนุษย์ การที่เราไม่ได้คิดหรือพูดเหมือนคนส่วนใหญ่ ไม่ได้แปลว่าเราผิดปกติแต่อาจเป็นเพียงความแตกต่างของคลื่นความถี่ที่เราเลือกใช้เท่านั้น

การเปลี่ยนมุมมองนี้ช่วยเยียวยาจิตใจได้ดีกว่าเดิม เพราะมันย้ำเตือนเราว่า "ความแตกต่าง" ไม่ได้เท่ากับ "ความเดียวดาย" เสมอไป ในทางจิตวิทยา การยอมรับและยืนหยัดในความเป็นตัวเอง (Authenticity) แม้จะดูแปลกแยกในตอนแรก คือก้าวสำคัญของสุขภาพจิตที่ดี

เราไม่จำเป็นต้องพยายามบิดเบือนคลื่นเสียงของตัวเองให้กลายเป็น 15-25Hz เหมือนวาฬส่วนใหญ่เพียงเพื่อให้ถูกนับรวมเข้าฝูง เพราะการฝืนทำในสิ่งที่ไม่ใช่ตัวเองจะนำไปสู่ความเหงาภายในที่ลึกซึ้งยิ่งกว่า

บทสรุปใหม่ของวาฬ 52Hz จึงให้ความหวังว่า การดำรงอยู่ด้วยความเป็นตัวเองอย่างแท้จริงนั้นมีคุณค่าเสมอ และที่ไหนสักแห่งในมหาสมุทรอันกว้างใหญ่นี้ ย่อมมีผู้ที่พร้อมจะรับฟังหรือเข้าใจคลื่นความถี่ที่เป็นเอกลักษณ์ของคุณอยู่จริง''',
    ),
    _HomeArticle(
      title: 'อยู่คนเดียวก็มีความ\nสุขดีนะ',
      subtitle: '3 Month Ago',
      imagePath: 'assets/images/article2.png',
      detailImagePath: 'assets/images/article2.png',
      detailTitle: 'อยู่คนเดียวก็มีความสุขดีนะ',
      content: '''
การอยู่คนเดียวไม่ได้หมายความว่าต้องเหงาเสมอไป การได้ใช้เวลากับตัวเองคือโอกาสที่ดีในการทำความเข้าใจความต้องการของตัวเอง พัฒนาทักษะใหม่ๆ และเติมพลังให้กับจิตใจ

ความสุขไม่ได้ขึ้นอยู่กับจำนวนคนรอบข้าง แต่อยู่ที่ความพึงพอใจในตัวเองและการมองเห็นคุณค่าในสิ่งเล็กๆ น้อยๆ รอบตัว ลองหาเวลาวันละนิดเพื่อทำสิ่งที่ชอบ หรือแค่นั่งจิบกาแฟเงียบๆ ก็อาจเป็นช่วงเวลาที่มีคุณภาพที่สุดของวันได้''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _videoClipsStream = _homeVideoRepository.watchVideoClips();
    _loadUsername();

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_currentBannerIndex < 2) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    setState(() => _isNameLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _displayName = 'ผู้ใช้';
        _isNameLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final username = response['username']?.toString().trim();

        if (!mounted) return;
        setState(() {
          _displayName =
              (username != null && username.isNotEmpty) ? username : 'ผู้ใช้';
          _isNameLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _displayName = 'ผู้ใช้';
          _isNameLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user from API: $e');
      if (!mounted) return;
      setState(() {
        _displayName = 'ผู้ใช้';
        _isNameLoading = false;
      });
    }
  }

  void _openVideoClip(List<HomeVideoClip> clips, int initialIndex) {
    if (clips.isEmpty) {
      return;
    }

    Get.to(
      () => PlayVideoPage(
        clips: clips,
        initialIndex: initialIndex,
      ),
    );
  }

  void _warmUpVisibleClips(
    BuildContext context,
    List<HomeVideoClip> clips,
  ) {
    final visibleClips = clips.take(2).toList(growable: false);
    final signature = visibleClips.map((clip) => clip.id).join('|');
    if (signature.isEmpty || signature == _lastWarmupSignature) {
      return;
    }

    _lastWarmupSignature = signature;
    unawaited(_homeVideoPrefetchService.warmUpClips(visibleClips));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      for (final clip in visibleClips) {
        final thumbnailPath = clip.thumbnailUrl?.trim() ?? '';
        if (thumbnailPath.startsWith('http')) {
          precacheImage(NetworkImage(thumbnailPath), context);
        }
      }
    });
  }

  String _clipCardTitle(HomeVideoClip clip) {
    final caption = clip.caption.trim();
    if (caption.isNotEmpty) {
      return caption;
    }
    return clip.authorName;
  }

  String _clipCardSubtitle(HomeVideoClip clip) {
    return '${clip.authorName} • ${clip.relativeTimeLabel}';
  }

  Future<void> _pickAndUploadClip() async {
    if (_isUploadingClip) {
      return;
    }

    final supportsCameraCapture = _supportsCameraVideoCapture;
    final source = await _promptClipSource();
    if (!mounted || source == null) {
      return;
    }

    if (supportsCameraCapture) {
      await _waitForModalToClose();
      if (!mounted) {
        return;
      }
    }

    await _pickAndUploadClipFromSource(source);
  }

  Future<void> _pickAndUploadClipFromSource(ImageSource source) async {
    try {
      final XFile? file;
      if (source == ImageSource.camera && _usesInAppCameraPage) {
        file = await Get.to<XFile>(() => const VideoCapturePage());
      } else {
        EntryFlowGuard.ignoreResumeFor(const Duration(seconds: 10));
        file = await _imagePicker.pickVideo(
          source: source,
        );
      }
      if (file == null || !mounted) {
        return;
      }

      final suggestedCaption = source == ImageSource.camera
          ? ''
          : _fileNameWithoutExtension(file.name);
      final caption = await _promptClipCaption(
        initialValue: suggestedCaption,
        videoFileName: file.name,
        videoFilePath: file.path,
      );
      if (!mounted || caption == null) {
        return;
      }

      await _waitForModalToClose();
      if (!mounted) {
        return;
      }

      final videoBytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() => _isUploadingClip = true);
      await _homeVideoRepository.createVideoClip(
        videoBytes: videoBytes,
        videoFileName: file.name,
        caption: caption,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โพสต์เรียบร้อยแล้ว!')),
      );
    } on UnimplementedError catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อุปกรณ์นี้ยังไม่รองรับการถ่ายวิดีโอจากแอป'),
          backgroundColor: Colors.red,
        ),
      );
    } on UnsupportedError catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อุปกรณ์นี้ยังไม่รองรับการถ่ายวิดีโอจากแอป'),
          backgroundColor: Colors.red,
        ),
      );
    } on HomeVideoBucketNotFoundException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยังไม่พบ Supabase Storage bucket ชื่อ ${error.bucketName}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } on HomeVideoUploadUnauthorizedException catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'อัปโหลดคลิปไม่ได้ เพราะ Supabase Storage ยังไม่เปิดสิทธิ์ให้ผู้ใช้เพิ่มไฟล์',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('source camera is not supported') ||
          message.contains('cameradelegate')) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อุปกรณ์นี้ยังไม่รองรับการถ่ายวิดีโอจากแอป'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปโหลดคลิปไม่สำเร็จ: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingClip = false);
      }
    }
  }

  Future<ImageSource?> _promptClipSource() async {
    if (!_supportsCameraVideoCapture) {
      return ImageSource.gallery;
    }

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ClipSourceSheet(),
    );
  }

  ImageProvider<Object> _composerAvatarImageProvider() {
    final avatarController = Get.isRegistered<ProfileAvatarController>()
        ? Get.find<ProfileAvatarController>()
        : Get.put(ProfileAvatarController());
    return avatarController.avatarImageProvider;
  }

  Future<String?> _promptClipCaption({
    required String initialValue,
    required String videoFileName,
    required String videoFilePath,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClipCaptionSheet(
        initialValue: initialValue,
        composerName: _displayName.trim().isEmpty ? 'ผู้ใช้' : _displayName,
        avatarImageProvider: _composerAvatarImageProvider(),
        videoFileName: videoFileName,
        videoFilePath: videoFilePath,
      ),
    );
  }

  Future<void> _waitForModalToClose() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  bool get _supportsCameraVideoCapture {
    return _usesInAppCameraPage || kIsWeb;
  }

  bool get _usesInAppCameraPage {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _fileNameWithoutExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, lastDotIndex);
  }

  Widget _buildAddClipCard() {
    final scale = context.responsive;
    final cardWidth = scale.rs(110, min: 96, max: 118);
    final loadingSize = scale.rs(26, min: 22, max: 28);
    final circleSize = scale.rs(45, min: 38, max: 48);

    return GestureDetector(
      onTap: _pickAndUploadClip,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E2E2),
          borderRadius: BorderRadius.circular(scale.rs(20, min: 16, max: 22)),
        ),
        child: Center(
          child: _isUploadingClip
              ? SizedBox(
                  width: loadingSize,
                  height: loadingSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Color(0xFF4489D7),
                  ),
                )
              : Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF8A8A8A),
                    size: scale.rs(30, min: 24, max: 32),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _openDailyMission() async {
    final message = await Get.to<String>(() => const DailyMoodPage());
    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final avatarController = Get.isRegistered<ProfileAvatarController>()
        ? Get.find<ProfileAvatarController>()
        : Get.put(ProfileAvatarController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
            final horizontalPadding = scale.rs(24, min: 14, max: 24);
            final bannerHeight = scale.rs(160, min: 145, max: 168);
            final articleCardWidth = scale.rs(160, min: 140, max: 168);
            final avatarSize = scale.rs(50, min: 44, max: 52);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await Get.to(() => const SettingPage());
                              if (!mounted) {
                                return;
                              }
                              await _loadUsername();
                            },
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: Obx(
                                () => Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image:
                                          avatarController.avatarImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isNameLoading ? 'สวัสดี, ...' : 'สวัสดี,$_displayName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF4489D7),
                          fontSize: scale.rf(24, min: 21, max: 25),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: bannerHeight,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                          children: [
                            DailyMissionBanner(
                              onTap: _openDailyMission,
                              dayCount: _defaultMissionDays.toString(),
                            ),
                            ClownFishBanner(),
                            LoveJobBanner(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBannerIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == index
                                  ? const Color(0xFF4489D7)
                                  : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      const HomeSectionHeader(title: 'คลิปสั้น'),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: scale.rs(160, min: 148, max: 168),
                        child: StreamBuilder<List<HomeVideoClip>>(
                          stream: _videoClipsStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError && !snapshot.hasData) {
                              return ListView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                padding: EdgeInsets.zero,
                                children: [_buildAddClipCard()],
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final clips =
                                snapshot.data ?? const <HomeVideoClip>[];
                            _warmUpVisibleClips(context, clips);
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              padding: EdgeInsets.zero,
                              itemCount: clips.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 15),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildAddClipCard();
                                }

                                final clip = clips[index - 1];
                                return InkWell(
                                  onTap: () => _openVideoClip(clips, index - 1),
                                  child: FutureBuilder<String?>(
                                    future: index <= 2
                                        ? _homeVideoPrefetchService
                                            .prefetchVideo(
                                            clip.videoUrl,
                                          )
                                        : _homeVideoPrefetchService
                                            .getCachedPath(
                                            clip.videoUrl,
                                          ),
                                    builder: (context, previewSnapshot) {
                                      final cachedPreviewPath =
                                          previewSnapshot.data?.trim() ?? '';
                                      return ClipCard(
                                        title: _clipCardTitle(clip),
                                        subtitle: _clipCardSubtitle(clip),
                                        imagePath: cachedPreviewPath.isNotEmpty
                                            ? cachedPreviewPath
                                            : clip.videoUrl,
                                        thumbnailPath: clip.thumbnailUrl,
                                        forceVideoPreview: true,
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                      const HomeSectionHeader(title: 'บทความจิตวิทยา'),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: EdgeInsets.zero,
                          itemCount: _articleList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 15),
                          itemBuilder: (context, index) {
                            final article = _articleList[index];
                            return SizedBox(
                              width: articleCardWidth,
                              child: ArticleCard(
                                title: article.title,
                                subtitle: article.subtitle,
                                imagePath: article.imagePath,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailPage(
                                        title: article.detailTitle,
                                        imagePath: article.detailImagePath,
                                        content: article.content,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
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

class _HomeArticle {
  const _HomeArticle({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.detailImagePath,
    required this.detailTitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final String detailImagePath;
  final String detailTitle;
  final String content;
}

class _ClipSourceSheet extends StatelessWidget {
  const _ClipSourceSheet();

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                scale.rs(24, min: 16, max: 24),
                scale.rs(20, min: 16, max: 20),
                scale.rs(24, min: 16, max: 24),
                scale.rs(24, min: 20, max: 24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: scale.rs(45, min: 36, max: 46),
                      height: 5,
                      margin: EdgeInsets.only(bottom: scale.rs(16, min: 12, max: 16)),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'เพิ่มคลิปวิดีโอ',
                    style: TextStyle(
                      fontSize: scale.rf(18, min: 16, max: 19),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4489D7),
                    ),
                  ),
                  SizedBox(height: scale.rs(6, min: 4, max: 7)),
                  Text(
                    'เลือกว่าจะอัดวิดีโอใหม่หรือใช้คลิปที่มีอยู่แล้ว',
                    style: TextStyle(
                      fontSize: scale.rf(14, min: 12.5, max: 14.5),
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  SizedBox(height: scale.rs(18, min: 14, max: 18)),
                  _ClipSourceActionTile(
                    icon: Icons.videocam_rounded,
                    title: 'ถ่ายวิดีโอ',
                    subtitle: 'เปิดกล้องเพื่ออัดคลิปแล้วนำมาโพสต์',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  SizedBox(height: scale.rs(12, min: 10, max: 12)),
                  _ClipSourceActionTile(
                    icon: Icons.video_library_rounded,
                    title: 'เลือกจากคลัง',
                    subtitle: 'ใช้วิดีโอที่มีอยู่แล้วในเครื่อง',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClipSourceActionTile extends StatelessWidget {
  const _ClipSourceActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4FAFF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF4489D7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4489D7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF4489D7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipCaptionSheet extends StatefulWidget {
  const _ClipCaptionSheet({
    required this.initialValue,
    required this.composerName,
    required this.avatarImageProvider,
    required this.videoFileName,
    required this.videoFilePath,
  });

  final String initialValue;
  final String composerName;
  final ImageProvider<Object> avatarImageProvider;
  final String videoFileName;
  final String videoFilePath;

  @override
  State<_ClipCaptionSheet> createState() => _ClipCaptionSheetState();
}

class _ClipCaptionSheetState extends State<_ClipCaptionSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  VideoPlayerController? _previewController;
  bool _isSubmitting = false;
  bool _isPreviewLoading = true;
  bool _isPreviewPlaying = false;
  bool _isPreviewUnavailable = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _initializeVideoPreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  Future<void> _initializeVideoPreview() async {
    final controller = createVideoPreviewController(widget.videoFilePath);
    try {
      await controller.setLooping(true);
      await controller.initialize();
      controller.addListener(_handlePreviewControllerChanged);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _previewController = controller;
        _isPreviewLoading = false;
        _isPreviewUnavailable = false;
        _isPreviewPlaying = controller.value.isPlaying;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _previewController = null;
        _isPreviewLoading = false;
        _isPreviewUnavailable = true;
        _isPreviewPlaying = false;
      });
    }
  }

  void _handlePreviewControllerChanged() {
    final controller = _previewController;
    if (controller == null || !mounted) {
      return;
    }

    final isPlaying = controller.value.isPlaying;
    if (isPlaying != _isPreviewPlaying) {
      setState(() => _isPreviewPlaying = isPlaying);
    }
  }

  Future<void> _togglePreviewPlayback() async {
    final controller = _previewController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    await controller.play();
  }

  void _removeSelectedVideo() {
    if (_isSubmitting) {
      return;
    }
    Navigator.of(context).pop();
  }

  double get _previewAspectRatio {
    final ratio = _previewController?.value.aspectRatio ?? (9 / 16);
    if (!ratio.isFinite || ratio <= 0) {
      return 9 / 16;
    }
    return ratio;
  }

  @override
  void dispose() {
    _previewController?.removeListener(_handlePreviewControllerChanged);
    unawaited(_previewController?.dispose());
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();
    final caption = _controller.text.trim();
    Navigator.of(context).pop(
      caption.isEmpty ? widget.initialValue : caption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = !_isSubmitting;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 10),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF8D8D8D),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'NewClip',
                          style: TextStyle(
                            color: Color(0xFF6C6C6C),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: widget.avatarImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.composerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C6C6C),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.image_rounded,
                            color: Colors.grey.shade600,
                            size: 26,
                          ),
                          onPressed: null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              focusNode: _focusNode,
                              autofocus: true,
                              controller: _controller,
                              maxLines: null,
                              maxLength: 120,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(fontSize: 16),
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                hintText: 'คุณกำลังคิดอะไรอยู่.....',
                                hintStyle: TextStyle(
                                  color: Color(0xFFCAC9C9),
                                  fontWeight: FontWeight.bold,
                                ),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 240),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: AspectRatio(
                                    aspectRatio: _previewAspectRatio,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (_isPreviewLoading)
                                          const ColoredBox(
                                            color: Color(0xFFF1F1F1),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF5CD9FF),
                                              ),
                                            ),
                                          )
                                        else if (_isPreviewUnavailable)
                                          ColoredBox(
                                            color: const Color(0xFFF1F1F1),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.videocam_off_rounded,
                                                    size: 34,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    widget.videoFileName,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else if (_previewController != null)
                                          GestureDetector(
                                            onTap: _togglePreviewPlayback,
                                            child: VideoPlayer(
                                              _previewController!,
                                            ),
                                          ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Material(
                                            color: Colors.black45,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: _removeSelectedVideo,
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!_isPreviewLoading &&
                                            !_isPreviewUnavailable &&
                                            !_isPreviewPlaying)
                                          Center(
                                            child: Material(
                                              color: Colors.white,
                                              shape: const CircleBorder(),
                                              child: InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: _togglePreviewPlayback,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Icon(
                                                    Icons.play_arrow_rounded,
                                                    size: 32,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 15,
                      left: 15,
                      top: 5,
                      bottom: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_controller.text.length}/120',
                              style: const TextStyle(
                                color: Color(0xFFC3C3C3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: canSubmit ? _submit : null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: canSubmit ? 1 : 0.55,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5CD9FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'POST',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
