import 'package:flutter/material.dart';
import '../helper.dart';
import 'add_card.dart';

class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({Key? key, required this.folder}) : super(key: key);

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.name} Cards'),
        actions: [
          FutureBuilder<int>(
            future: dbHelper.getFolderCardCount(widget.folder.id!),
            builder: (context, snapshot) {
              final cardCount = snapshot.data ?? 0;
              final isDisabled = cardCount >= 6;

              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: isDisabled
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This folder can only hold 6 cards'),
                          ),
                        );
                      }
                    : () async {
                        final added = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddCardScreen(
                              folder: widget.folder,
                            ),
                          ),
                        );
                        if (added == true) {
                          setState(() {});
                        }
                      },
                tooltip: 'Add Card',
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Cards>>(
        future: dbHelper.getCardsInFolder(widget.folder.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No cards in this folder yet'),
            );
          }

          final cards = snapshot.data!;
          final cardCount = cards.length;

          return Column(
            children: [
              // Warning for minimum card count
              if (cardCount < 3)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'You need at least 3 cards in this folder. Current count: $cardCount',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),

              // Cards grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return CardGridItem(
                      card: card,
                      onDelete: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Card?'),
                            content: Text(
                              'Are you sure you want to remove ${card.name} from this folder?'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (result == true) {
                          await dbHelper.removeCardFromFolder(card.id!);
                          setState(() {});
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('${card.name} removed from folder'),
                            ),
                          );
                        }
                      },
                      onReassign: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final folders = await dbHelper.getAllFolders();
                        
                        final selectedFolder = await showDialog<Folder>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Move Card to Different Folder'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 300,
                              child: ListView.builder(
                                itemCount: folders.length,
                                itemBuilder: (context, index) {
                                  final folder = folders[index];
                                  if (folder.id == widget.folder.id) {
                                    return const SizedBox.shrink();
                                  }
                                  return ListTile(
                                    title: Text(folder.name),
                                    onTap: () => Navigator.pop(context, folder),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (selectedFolder != null) {
                          // Check if target folder is full
                          final targetFolderCardCount = 
                              await dbHelper.getFolderCardCount(selectedFolder.id!);
                              
                          if (targetFolderCardCount >= 6) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Target folder is full (max 6 cards)'),
                              ),
                            );
                            return;
                          }
                          
                          await dbHelper.updateCard(
                            Cards(
                              id: card.id,
                              name: card.name,
                              suit: card.suit,
                              imageUrl: card.imageUrl,
                              folderId: selectedFolder.id,
                            ),
                          );
                          setState(() {});
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${card.name} moved to ${selectedFolder.name}'
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CardGridItem extends StatelessWidget {
  final Cards card;
  final VoidCallback onDelete;
  final VoidCallback onReassign;

  const CardGridItem({
    Key? key,
    required this.card,
    required this.onDelete,
    required this.onReassign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card image
            Expanded(
              child: Image.asset(
                card.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            // Card details
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reassign button
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: 'Move to another folder',
                        onPressed: onReassign,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Remove button
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove from folder',
                        onPressed: onDelete,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}