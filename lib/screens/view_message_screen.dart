import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/message.dart';
import '../models/database.dart';
import 'edit_message_screen.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import '../services/social_service.dart';
import 'full_screen_image_view.dart';

class ViewMessageScreen extends StatefulWidget {
  final Message message;

  const ViewMessageScreen({Key? key, required this.message}) : super(key: key);

  @override
  _ViewMessageScreenState createState() => _ViewMessageScreenState();
}

class _ViewMessageScreenState extends State<ViewMessageScreen> {
  late Message _message;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SocialService _socialService = SocialService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  Future<void> _deleteMessage() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Message'),
            content: Text('Are you sure you want to delete this message?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _databaseHelper.deleteMessage(_message.id!);
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting message: $e')));
      }
    }
  }

  Future<void> _shareMessage() async {
    try {
      if (_message.imagePath != null &&
          File(_message.imagePath!).existsSync()) {
        // Share both text and image
        final files = [XFile(_message.imagePath!)];
        await Share.shareXFiles(
          files,
          text: _message.content,
          subject: _message.title,
        );
      } else {
        // Just share text if no image
        await Share.share(_message.content, subject: _message.title);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing message: $e')));
    }
  }

  Future<void> _uploadToSocialMedia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we're configured first (now checks webhook URL)
      final isAuth = await _socialService.isAuthenticated();
      print('Configuration status (Discord Webhook): $isAuth');

      // If not configured, show error
      if (!isAuth) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          // Updated SnackBar text
          SnackBar(content: Text('Discord Webhook URL not configured correctly.')),
        );
        return;
      }

      // Check if the message has an image (Discord webhook requires it in this implementation)
      print('Message image path: ${_message.imagePath}');
      if (_message.imagePath == null) {
        print('Error: No image path in message for Discord upload');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message has no image to upload to Discord')),
        );
        return;
      }

      // Check if the image file exists
      final file = File(_message.imagePath!);
      final exists = await file.exists();
      print('Image file exists: $exists');
      if (!exists) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image file not found')));
        return;
      }

      // Now try to upload - using uploadMessageBool which returns boolean
      final result = await _socialService.uploadMessageBool(_message);
      print('Discord Upload result: $result'); // Updated print statement slightly

      if (result) {
        // Success path
        final updatedMessage = _message.copyWith(isUploaded: true);
        await _databaseHelper.updateMessage(updatedMessage);
        setState(() {
          _message = updatedMessage;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          // Updated SnackBar text
          SnackBar(content: Text('Message uploaded successfully to Discord')),
        );
      } else {
        // Failure path
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            // Updated SnackBar text
            SnackBar(content: Text('Failed to upload message to Discord')));
      }
    } catch (e) {
      // Generic error path
      print('Upload error: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          // Updated SnackBar text
          SnackBar(content: Text('Error uploading message to Discord: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('View Message'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMessageScreen(message: _message),
                ),
              );
              if (result != null && result is Message) {
                setState(() {
                  _message = result;
                });
              }
            },
          ),
          IconButton(icon: Icon(Icons.delete), onPressed: _deleteMessage),
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'share', child: Text('Share')),
                  PopupMenuItem(
                    value: 'upload',
                    child: Text('Upload to Social Media'),
                  ),
                  PopupMenuItem(value: 'copy', child: Text('Copy Content')),
                ],
            onSelected: (value) async {
              switch (value) {
                case 'share':
                  await _shareMessage();
                  break;
                case 'upload':
                  await _uploadToSocialMedia();
                  break;
                case 'copy':
                  await Clipboard.setData(
                    ClipboardData(text: _message.content),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Content copied to clipboard')),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _message.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Updated: ${dateFormat.format(_message.updatedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 8),
                        if (_message.isUploaded)
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_done,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (_message.imagePath != null) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FullScreenImageView(
                                    imagePath: _message.imagePath!,
                                  ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_message.imagePath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    Text(_message.content, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
    );
  }
}
