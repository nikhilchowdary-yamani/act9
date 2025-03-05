import 'package:flutter/material.dart';
import '../helper.dart';

class AddCardScreen extends StatefulWidget {
  final Folder folder;

  const AddCardScreen({Key? key, required this.folder}) : super(key: key);

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final dbHelper = DatabaseHelper.instance;
  String? selectedSuit;
  List<Cards> availableCards = [];
  List<Cards> filteredCards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCards();
  }

  Future<void> _loadAvailableCards() async {
    setState(() {
      isLoading = true;
    });

    availableCards = await dbHelper.getAvailableCards();
    filteredCards = availableCards;

    setState(() {
      isLoading = false;
    });
  }

  void _filterCards(String? suit) {
    setState(() {
      selectedSuit = suit;
      if (suit == null) {
        filteredCards = availableCards;
      } else {
        filteredCards = availableCards.where((card) => card.suit == suit).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Card to ${widget.folder.name}'),
      ),
      body: Column(
        children: [
          // Filter by suit
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Filter by suit:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedSuit,
                    hint: const Text('All Suits'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Suits'),
                      ),
                      ...['Hearts', 'Spades', 'Diamonds', 'Clubs'].map((suit) {
                        return DropdownMenuItem<String>(
                          value: suit,
                          child: Text(suit),
                        );
                      }).toList(),
                    ],
                    onChanged: _filterCards,
                  ),
                ),
              ],
            ),
          ),

          // Cards grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCards.isEmpty
                    ? const Center(child: Text('No cards available'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = filteredCards[index];
                          return AvailableCardItem(
                            card: card,
                            onAdd: () async {
                              final result = await dbHelper.addCardToFolder(
                                card.id!,
                                widget.folder.id!,
                              );

                              if (result == -1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This folder can only hold 6 cards'),
                                  ),
                                );
                              } else {
                                // Remove the card from available cards
                                setState(() {
                                  availableCards.remove(card);
                                  if (selectedSuit == null) {
                                    filteredCards = availableCards;
                                  } else {
                                    filteredCards = availableCards
                                        .where((c) => c.suit == selectedSuit)
                                        .toList();
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${card.name} added to folder'),
                                  ),
                                );

                                // If we added a card, we'll return true
                                Navigator.pop(context, true);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class AvailableCardItem extends StatelessWidget {
  final Cards card;
  final VoidCallback onAdd;

  const AvailableCardItem({
    Key? key,
    required this.card,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color suitColor;
    switch (card.suit) {
      case 'Hearts':
      case 'Diamonds':
        suitColor = Colors.red;
        break;
      case 'Spades':
      case 'Clubs':
        suitColor = Colors.black;
        break;
      default:
        suitColor = Colors.black;
    }

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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: suitColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Add to Folder'),
                    ),
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