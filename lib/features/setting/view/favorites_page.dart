import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/core/responsive/responsive_scale.dart';
import 'package:flutter_application_1/features/feed/view/feed_view.dart';
import 'package:flutter_application_1/features/profile/model/profile_avatar_catalog.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesController extends GetxController {
  FavoritesController({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> favoriteItems =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        favoriteItems.clear();
        return;
      }

      final savedPostRows = await _supabase.rpc(
        'get_saved_posts',
        params: {
          'p_limit': 300,
          'p_offset': 0,
        },
      );

      if (savedPostRows is! List) {
        favoriteItems.clear();
        return;
      }

      final normalizedSavedRows = savedPostRows
          .whereType<Map>()
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList()
        ..sort(
          (a, b) => _parseSavedAt(b).compareTo(_parseSavedAt(a)),
        );

      if (normalizedSavedRows.isEmpty) {
        favoriteItems.clear();
        return;
      }

      final authorIds = <String>{};
      for (final postData in normalizedSavedRows) {
        final authorId = postData['user_id']?.toString() ?? '';
        if (authorId.isNotEmpty) {
          authorIds.add(authorId);
        }
      }

      final authorNameById = <String, String>{};
      final authorAvatarById = <String, String>{};
      if (authorIds.isNotEmpty) {
        try {
          final profileRows = await _supabase
              .from('profiles')
              .select('id, username, avatarurl')
              .inFilter('id', authorIds.toList());

          for (final row in profileRows) {
            final map = Map<String, dynamic>.from(row);
            final authorId = map['id']?.toString() ?? '';
            if (authorId.isEmpty) {
              continue;
            }

            final username = map['username']?.toString().trim() ?? '';
            if (username.isNotEmpty) {
              authorNameById[authorId] = username;
            }

            authorAvatarById[authorId] = ProfileAvatarCatalog.normalize(
              map['avatarurl']?.toString(),
            );
          }
        } catch (_) {
          // Keep showing favorites even if profile fetch fails.
        }
      }

      final loadedItems = <Map<String, dynamic>>[];
      final seenPostIds = <String>{};
      for (final postData in normalizedSavedRows) {
        final postId = _extractPostId(postData);
        if (postId.isEmpty || seenPostIds.contains(postId)) {
          continue;
        }
        seenPostIds.add(postId);

        final authorId = postData['user_id']?.toString() ?? '';
        final postTitle = (authorNameById[authorId] ?? '').trim();
        final fallbackTitle = postData['title']?.toString().trim() ?? '';
        final content = _extractContent(postData);
        final profileImage =
            authorAvatarById[authorId] ?? ProfileAvatarCatalog.defaultAvatar;

        loadedItems.add({
          'post_id': postId,
          'date': _formatDate(_savedAtValue(postData)),
          'title': postTitle.isNotEmpty
              ? postTitle
              : (fallbackTitle.isNotEmpty ? fallbackTitle : 'โพสต์'),
          'content': content,
          'image_url': profileImage,
        });
      }

      favoriteItems.assignAll(loadedItems);
    } catch (error, stackTrace) {
      debugPrint('Favorites fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      final detail = error is PostgrestException
          ? error.message
          : 'ไม่สามารถโหลดรายการโปรดได้';
      Get.snackbar('ข้อผิดพลาด', detail);
    } finally {
      isLoading.value = false;
    }
  }

  String _extractContent(Map<String, dynamic> postData) {
    final candidates = [
      postData['content_text'],
      postData['content'],
      postData['caption'],
      postData['body'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is String) {
      final parsedDate = DateTime.tryParse(createdAt);
      if (parsedDate != null) {
        return DateFormat('MMMM dd, yyyy').format(parsedDate);
      }
    }

    return '-';
  }

  dynamic _savedAtValue(Map<String, dynamic> row) {
    return row['saved_at'] ?? row['updated_at'] ?? row['created_at'];
  }

  String _extractPostId(Map<String, dynamic> row) {
    final candidates = <dynamic>[
      row['id'],
      row['post_id'],
      row['saved_post_id'],
      row['user_saved_posts'],
    ];
    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          final postId = item?.toString().trim() ?? '';
          if (postId.isNotEmpty) {
            return postId;
          }
        }
        continue;
      }
      final postId = candidate?.toString().trim() ?? '';
      if (postId.isNotEmpty) {
        return postId;
      }
    }
    return '';
  }

  DateTime _parseSavedAt(Map<String, dynamic> row) {
    final raw = _savedAtValue(row);
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<FavoritesController>()) {
      _controller = Get.find<FavoritesController>();
    } else {
      _controller = Get.put(FavoritesController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<FavoritesController>()) {
      Get.delete<FavoritesController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appScale = context.responsive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: appScale.rs(40, min: 34, max: 40),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Padding(
            padding: EdgeInsets.only(
              left: appScale.rs(10, min: 8, max: 10),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/back.png',
                width: appScale.rs(25, min: 20, max: 25),
                height: appScale.rs(25, min: 20, max: 25),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        titleSpacing: 2,
        title: Text(
          'รายการโปรด',
          style: TextStyle(
            color: Color(0xFF4489D7),
            fontSize: appScale.rf(22, min: 18, max: 22),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = ResponsiveScale.fromWidth(constraints.maxWidth);
          final horizontalPadding = constraints.maxWidth < 360
              ? scale.rs(14, min: 10, max: 14)
              : scale.rs(20, min: 14, max: 20);

          return Obx(() {
            if (_controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4489D7)),
              );
            }

            if (_controller.favoriteItems.isEmpty) {
              return Center(
                child: Text(
                  'ยังไม่มีรายการโปรด',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: scale.rf(16, min: 14, max: 16),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: scale.rs(10, min: 8, max: 10),
                  ),
                  itemCount: _controller.favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = _controller.favoriteItems[index];
                    final bool showDateHeader = index == 0 ||
                        item['date'] !=
                            _controller.favoriteItems[index - 1]['date'];

                    final imageUrl = item['image_url']?.toString() ?? '';
                    final imageProvider = _buildImageProvider(imageUrl);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader) ...[
                          SizedBox(height: scale.rs(10, min: 8, max: 10)),
                          Text(
                            item['date']?.toString() ?? '-',
                            style: TextStyle(
                              color: const Color(0xFF4489D7),
                              fontSize: scale.rf(18, min: 15, max: 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: scale.rs(10, min: 8, max: 10)),
                        ],
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: scale.rs(10, min: 8, max: 10),
                          ),
                          child: InkWell(
                            onTap: () => _openFavoritePost(item),
                            borderRadius: BorderRadius.circular(
                              scale.rs(10, min: 8, max: 10),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: scale.rs(4, min: 2, max: 4),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: scale.rs(25, min: 20, max: 25),
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: imageProvider,
                                        child: imageProvider == null
                                            ? Icon(
                                                Icons.image_outlined,
                                                color: Colors.grey[500],
                                                size: scale.rs(20,
                                                    min: 16, max: 20),
                                              )
                                            : null,
                                      ),
                                      SizedBox(
                                        width: scale.rs(10, min: 8, max: 10),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title']?.toString() ??
                                                  'ไม่มีชื่อโพสต์',
                                              style: TextStyle(
                                                color: const Color(0xFF757575),
                                                fontSize: scale.rf(
                                                  18,
                                                  min: 15,
                                                  max: 18,
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  scale.rs(2, min: 1, max: 2),
                                            ),
                                            Text(
                                              item['content']?.toString() ?? '',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: const Color(0xFF9E9E9E),
                                                fontSize: scale.rf(
                                                  14,
                                                  min: 12,
                                                  max: 14,
                                                ),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: scale.rs(15, min: 10, max: 15),
                                  ),
                                  Divider(
                                    color: const Color(0xFFD9D9D9),
                                    thickness: scale.rs(1.2, min: 1, max: 1.2),
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          });
        },
      ),
    );
  }

  ImageProvider<Object>? _buildImageProvider(String rawImage) {
    final image = rawImage.trim();
    if (image.isEmpty) {
      return null;
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }

    if (image.startsWith('assets/')) {
      return AssetImage(image);
    }

    return null;
  }

  void _openFavoritePost(Map<String, dynamic> item) {
    final postId = item['post_id']?.toString().trim() ?? '';
    if (postId.isEmpty) {
      Get.snackbar('ข้อผิดพลาด', 'ไม่พบโพสต์ที่เลือก');
      return;
    }

    Get.to(() => FeedPage(focusPostId: postId));
  }
}
