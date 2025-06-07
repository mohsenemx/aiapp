// lib/widgets/message_input.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String text, XFile? image) onSend;
  final String hintText;
  final bool enabled;
  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.hintText = 'هرچی میخوایی بپرس...',
    this.enabled = true,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  int pointsNeeded = 0;
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        pointsNeeded += 100;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      pointsNeeded -= 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kbHeight),
      child: ValueListenableBuilder<bool>(
        valueListenable: isDarkNotifier,
        builder: (_, isDark, __) {
          final bg = Theme.of(context).colorScheme.surface;
          final boxColor = isDark ? const Color.fromRGBO(9, 27, 24, 1) : bg;
          final primary = Theme.of(context).colorScheme.primary;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedImage != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary, width: 3),
                        ),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 120,
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 2,
                              child: GestureDetector(
                                onTap: _clearImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: widget.controller,
                        maxLines: 10,
                        minLines: 2,
                        onChanged: (value) {
                          setState(() {
                            pointsNeeded = value.split(' ').length * 2;
                          });
                        },

                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: isDarkNotifier,
                        builder: (_, isDark, __) {
                          return Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                backgroundColor: primary,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'camera') {
                                      _pickImage(ImageSource.camera);
                                    } else if (value == 'gallery') {
                                      _pickImage(ImageSource.gallery);
                                    }
                                  },
                                  itemBuilder:
                                      (_) => [
                                        PopupMenuItem(
                                          value: 'camera',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                size: 20,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'دوربین',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'gallery',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.photo_library,
                                                size: 20,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'گالری',
                                                style: TextStyle(fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.ideographic,
                                children: [
                                  Text(
                                    NumberFormat.decimalPattern(
                                      'fa',
                                    ).format(pointsNeeded),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.star,
                                    size: 30,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                              // send button
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: primary,
                                  child:
                                      widget.enabled
                                          ? IconButton(
                                            style: ButtonStyle(),
                                            icon: Icon(
                                              Icons.arrow_upward,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                pointsNeeded = 0;
                                              });

                                              widget.onSend(
                                                widget.controller.text.trim(),
                                                _pickedImage,
                                              );
                                              _clearImage();
                                            },
                                          )
                                          : Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
