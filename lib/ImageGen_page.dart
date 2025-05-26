// lib/image_generation_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/app_drawer.dart';
import 'services/api_service.dart';
import 'models/ImageGen.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'main.dart';

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
    // 1️⃣ Ask for storage/gallery permissions
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage permission is required to save images.'),
        ),
      );
      return;
    }

    try {
      // 2️⃣ Fetch the image bytes
      final uri = Uri.parse(image.url);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // 3️⃣ Write to a temporary file
      final bytes = resp.bodyBytes;
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // infer extension from URL or default to .png
      final ext = image.url.split('.').last.split('?').first;
      final filename = 'IMG_$timestamp.$ext';
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 4️⃣ Save to gallery
      final success = await GallerySaver.saveImage(file.path);
      if (success == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image saved to gallery!')));
      } else {
        throw Exception('Gallery save failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final images = await ApiService.instance.getUserImages();
      setState(() => _history = images);
    } catch (e) {
      // TODO: show error snack
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _loading = true);
    try {
      final gen = await ApiService.instance.sendImageGeneration(prompt: prompt);
      setState(() {
        _history.insert(0, gen);
        _loadHistory();
        _promptController.clear();
      });
    } catch (e) {
      // TODO: show error snack
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
                ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text(
                    'ساخت تصویر',
                    style: TextStyle(color: Colors.white),
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
