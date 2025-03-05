import 'package:flutter/material.dart';
import '../helper.dart';

class AddFolderScreen extends StatefulWidget {
  const AddFolderScreen({Key? key}) : super(key: key);

  @override
  _AddFolderScreenState createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends State<AddFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Folder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a folder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final folderName = _nameController.text;
                    final timestamp = DateTime.now().toIso8601String();
                    
                    final folder = Folder(
                      name: folderName,
                      timestamp: timestamp,
                    );
                    
                    await dbHelper.createFolder(folder);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Folder "$folderName" created')),
                    );
                    
                    Navigator.pop(context, true);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('CREATE FOLDER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}