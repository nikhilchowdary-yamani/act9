import 'package:flutter/material.dart';
import '../helper.dart';
import 'card.dart';
import 'add_folder.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFolderScreen()),
              );
              if (added == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Folder>>(
        future: dbHelper.getAllFolders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No folders found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final folder = snapshot.data![index];
              return FolderListItem(folder: folder, onUpdate: () => setState(() {}));
            },
          );
        },
      ),
    );
  }
}

class FolderListItem extends StatelessWidget {
  final Folder folder;
  final VoidCallback onUpdate;

  const FolderListItem({
    Key? key,
    required this.folder,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;

    return FutureBuilder<List<Cards>>(
      future: dbHelper.getCardsInFolder(folder.id!),
      builder: (context, snapshot) {
        final cardCount = snapshot.hasData ? snapshot.data!.length : 0;
        final firstCardImage = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data![0].imageUrl
            : 'assets/cards/placeholder.png';
        
        String warningText = '';
        Color warningColor = Colors.black;
        
        if (cardCount < 3) {
          warningText = ' (Need at least 3 cards)';
          warningColor = Colors.orange;
        } else if (cardCount >= 6) {
          warningText = ' (Folder full)';
          warningColor = Colors.red;
        }
 
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(folder: folder),
                ),
              );
              onUpdate();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Folder preview image
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: AssetImage(firstCardImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: cardCount == 0
                        ? const Center(child: Text('Empty'))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Folder details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$cardCount cards$warningText',
                          style: TextStyle(
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit/Delete buttons
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final TextEditingController controller = TextEditingController(text: folder.name);
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Rename Folder'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Folder Name',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          
                          if (newName != null && newName.isNotEmpty) {
                            final updatedFolder = Folder(
                              id: folder.id,
                              name: newName,
                              timestamp: folder.timestamp,
                            );
                            await dbHelper.updateFolder(updatedFolder);
                            onUpdate();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Folder renamed to $newName')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          // First check if folder has cards
                          final cardCount = await dbHelper.getFolderCardCount(folder.id!);
                          
                          if (cardCount > 0) {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Folder?'),
                                content: Text('This folder contains $cardCount cards. They will be moved back to the deck. Continue?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (result != true) return;
                          } else {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Folder?'),
                                content: const Text('Are you sure you want to delete this folder?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (result != true) return;
                          }
                          
                          await dbHelper.deleteFolder(folder.id!);
                          onUpdate();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Folder deleted')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}