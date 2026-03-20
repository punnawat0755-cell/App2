import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/core/services/entry_flow_guard.dart';
import 'package:flutter_application_1/features/home/model/home_video_clip.dart';
import 'package:flutter_application_1/features/home/service/home_video_prefetch_service.dart';
import 'package:flutter_application_1/features/home/service/home_video_repository.dart';
import 'package:flutter_application_1/features/home/view/daily_mood_page.dart';
import 'package:flutter_application_1/features/home/view/play_video_page.dart';
import 'package:flutter_application_1/features/home/view/video_capture_page.dart';
import 'package:flutter_application_1/features/home/view/widgets/article/article_card.dart';
import 'package:flutter_application_1/features/home/view/widgets/article/article_detail.dart';
import 'package:flutter_application_1/features/home/view/widgets/home_widgets.dart';
import 'package:flutter_application_1/features/profile/controller/profile_avatar_controller.dart';
import 'package:flutter_application_1/features/setting/view/setting.dart';
import 'package:flutter_application_1/core/supabase/supabase_client.dart';

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
      final caption = await _promptClipCaption(suggestedCaption);
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

  Future<String?> _promptClipCaption(String initialValue) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClipCaptionSheet(
        initialValue: initialValue,
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
    return GestureDetector(
      onTap: _pickAndUploadClip,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _isUploadingClip
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Color(0xFF4489D7),
                  ),
                )
              : Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF8A8A8A),
                    size: 30,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await Get.to(() => const SettingPage());
                          if (!mounted) {
                            return;
                          }
                          await _loadUsername();
                        },
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Obx(
                            () => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: avatarController.avatarImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _isNameLoading ? 'สวัสดี, ...' : 'สวัสดี,$_displayName',
                style: const TextStyle(
                  color: Color(0xFF4489D7),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 160,
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
                height: 160,
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    final clips = snapshot.data ?? const <HomeVideoClip>[];
                    _warmUpVisibleClips(context, clips);
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.zero,
                      itemCount: clips.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 15),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildAddClipCard();
                        }

                        final clip = clips[index - 1];
                        return InkWell(
                          onTap: () => _openVideoClip(clips, index - 1),
                          child: FutureBuilder<String?>(
                            future: index <= 2
                                ? _homeVideoPrefetchService.prefetchVideo(
                                    clip.videoUrl,
                                  )
                                : _homeVideoPrefetchService.getCachedPath(
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
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final article = _articleList[index];
                    return SizedBox(
                      width: 160,
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    'เพิ่มคลิปวิดีโอ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4489D7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'เลือกว่าจะอัดวิดีโอใหม่หรือใช้คลิปที่มีอยู่แล้ว',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ClipSourceActionTile(
                    icon: Icons.videocam_rounded,
                    title: 'ถ่ายวิดีโอ',
                    subtitle: 'เปิดกล้องเพื่ออัดคลิปแล้วนำมาโพสต์',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
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
  });

  final String initialValue;

  @override
  State<_ClipCaptionSheet> createState() => _ClipCaptionSheetState();
}

class _ClipCaptionSheetState extends State<_ClipCaptionSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final caption = _controller.text.trim();
    Navigator.of(context).pop(
      caption.isEmpty ? widget.initialValue : caption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Text(
                      'เพิ่มคำบรรยายคลิป',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4489D7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'เช่น วันนี้ขอพักใจนิดนึง',
                        filled: true,
                        fillColor: const Color(0xFFF4FAFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4489D7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _submit,
                        child: const Text('บันทึกคลิป'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
