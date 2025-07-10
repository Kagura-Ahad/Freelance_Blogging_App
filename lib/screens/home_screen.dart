import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/database.dart';
import 'create_message_screen.dart';
import 'view_message_screen.dart';
import 'search_screen.dart';
import '../widgets/message_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Message> _messages = [];
  List<int> _selectedMessageIds = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await _databaseHelper.getMessages();
    setState(() {
      _messages = messages;
    });
  }

  Future<void> _deleteSelectedMessages() async {
    await _databaseHelper.deleteMessages(_selectedMessageIds);
    setState(() {
      _selectedMessageIds = [];
      _isSelectionMode = false;
    });
    _loadMessages();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Selected messages deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Blog'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed:
                  _selectedMessageIds.isNotEmpty
                      ? _deleteSelectedMessages
                      : null,
            ),
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _selectedMessageIds = [];
                  _isSelectionMode = false;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
                _loadMessages();
              },
            ),
            PopupMenuButton(
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'select',
                      child: Text('Select Messages'),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'select') {
                  setState(() {
                    _isSelectionMode = true;
                  });
                }
              },
            ),
          ],
        ],
      ),
      body:
          _messages.isEmpty
              ? Center(
                child: Text(
                  'No message yet. Create your first message!',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMessages,
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isSelected = _selectedMessageIds.contains(message.id);

                    return MessageCard(
                      message: message,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedMessageIds.remove(message.id);
                            } else {
                              _selectedMessageIds.add(message.id!);
                            }
                          });
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ViewMessageScreen(message: message),
                            ),
                          ).then((_) => _loadMessages());
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedMessageIds.add(message.id!);
                          });
                        }
                      },
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMessageScreen()),
          ).then((_) => _loadMessages());
        },
        child: Icon(Icons.add),
        tooltip: 'Create New Message',
      ),
    );
  }
}
