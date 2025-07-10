import 'package:flutter/material.dart';
import 'dart:io';
import '../models/message.dart';
import '../models/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditMessageScreen extends StatefulWidget {
  final Message message;

  const EditMessageScreen({Key? key, required this.message}) : super(key: key);

  @override
  _EditMessageScreenState createState() => _EditMessageScreenState();
}

class _EditMessageScreenState extends State<EditMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final ImagePicker _imagePicker = ImagePicker();
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.message.title);
    _contentController = TextEditingController(text: widget.message.content);
    _imagePath = widget.message.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        // Copy the image to the app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(pickedFile.path);
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');

        setState(() {
          _imagePath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _updateMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedMessage = widget.message.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          imagePath: _imagePath,
          updatedAt: DateTime.now(),
        );

        await _databaseHelper.updateMessage(updatedMessage);

        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context, updatedMessage);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating message: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Message'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _isLoading ? null : _updateMessage,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      if (_imagePath != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          icon: Icon(Icons.delete),
                          label: Text('Remove Image'),
                          onPressed: () {
                            setState(() {
                              _imagePath = null;
                            });
                          },
                        ),
                        SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.photo_library),
                            label: Text('Gallery'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt),
                            label: Text('Camera'),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
