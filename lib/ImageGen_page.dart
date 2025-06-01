// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'widgets/app_drawer.dart';
import 'services/api_service.dart';
import 'models/ImageGen.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'main.dart';
import 'widgets/ui_helper.dart';

class ImageGenerationPage extends StatefulWidget {
  final String userId;
  final VoidCallback toggleTheme;

  const ImageGenerationPage({
    Key? key,
    required this.userId,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  _ImageGenerationPageState createState() => _ImageGenerationPageState();
}

class _ImageGenerationPageState extends State<ImageGenerationPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _loading = false;
  List<ImageGeneration> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _downloadImage(ImageGeneration image) async {
    try {
      final response = await Dio().get(
        image.url,
        options: Options(responseType: ResponseType.bytes),
      );

      final Uint8List bytes = Uint8List.fromList(response.data);
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'image_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result['isSuccess']) {
        showSnackBar(context, 'با موفقیت دانلود شد.');
      }
    } catch (e) {
      showSnackBar(context, 'مشکلی در ذخیره تصویر رخ داد', error: true);
    }
  }

  Future<void> _fetchStars() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fetched = await ApiService.instance.getStars();
      if (!mounted) return;
      setState(() {
        stars = fetched;
      });
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final images = await ApiService.instance.getUserImages();
      setState(() => _history = images);
      _fetchStars();
    } catch (e) {
      showSnackBar(context, 'مشکلی در بازگذاری تصاویر پیش آمد', error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _loading = true);
    showSnackBar(context, 'ساخت عکس بعد از تبلیغ کوتاهی شروع میشود.');
    try {
      final responseId = await TapsellPlus.instance.requestInterstitialAd(
        '683872f36280794748a5d9f2',
      );
      TapsellPlus.instance.showInterstitialAd(
        responseId,
        onOpened: (map) {
          // Ad opened - Map contains zone_id and response_id
          print('Ad shows!');
        },
        onError: (map) {
          // Ad failed to show - Map contains error_message, zone_id and response_id
          print('Failed to show ads?');
        },
      );
    } catch (e) {
      print(e);
      print('Failed to load ad');
    }
    try {
      final gen = await ApiService.instance.sendImageGeneration(prompt: prompt);
      setState(() {
        _history.insert(0, gen);
        _loadHistory();
        _promptController.clear();
      });
    } catch (e) {
      showSnackBar(context, "به اندازه کافی ستاره ندارید", error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mstars = NumberFormat.decimalPattern('fa').format(stars);
    return Scaffold(
      drawer: AppDrawer(userId: widget.userId, toggleTheme: widget.toggleTheme),
      appBar: AppBar(
        title: Text('تصویرسازی'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(mstars, style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                const Icon(Icons.star),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    labelText: 'متن شما',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: _loading ? null : _generate,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Text(
                          'ساخت تصویر',
                          style: TextStyle(color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              NumberFormat.decimalPattern('fa').format(300),
                              style: TextStyle(color: Colors.white),
                            ),
                            Icon(Icons.star, color: Colors.white),
                            Text('-', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _history.length,
                itemBuilder: (_, i) {
                  final gen = _history[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (gen.url.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                  child: Image.network(
                                    gen.url,
                                    fit: BoxFit.cover,
                                    height: 180,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gen.prompt,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat.yMMMd(
                                      'fa',
                                    ).add_Hm().format(gen.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                _downloadImage(_history[i]);
                              },

                              child: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.5),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Icon(
                                    Icons.download,
                                    size: 25,
                                    color: const Color.fromARGB(
                                      150,
                                      255,
                                      255,
                                      255,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
