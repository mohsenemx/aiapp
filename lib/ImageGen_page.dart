// lib/image_generation_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/app_drawer.dart';
import 'services/api_service.dart';
import 'models/ImageGen.dart';
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
  final TextEditingController _negativeController = TextEditingController();
  bool _loading = false;
  List<ImageGeneration> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
      // this assumes you added a method sendImageGeneration in ApiService:
      final gen = await ApiService.instance.sendImageGeneration(
        prompt: prompt,
        negativePrompt: _negativeController.text.trim(),
      );
      setState(() {
        _history.insert(0, gen);
        _promptController.clear();
        _negativeController.clear();
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
                    labelText: 'Prompt',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _negativeController,
                  decoration: InputDecoration(
                    labelText: 'Negative prompt (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.image),
                  label: const Text('Generate Image'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (gen.url.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            child: Image.network(
                              gen.url,
                              fit: BoxFit.cover,
                              height: 180,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gen.prompt,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (gen.negativePrompt.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Avoid: ${gen.negativePrompt}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
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
    _negativeController.dispose();
    super.dispose();
  }
}
