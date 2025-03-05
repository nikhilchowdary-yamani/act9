import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class Folder {
  final int? id;
  final String name;
  final String timestamp;

  Folder({this.id, required this.name, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      timestamp: map['timestamp'],
    );
  }
}

class Cards {
  final int? id;
  final String name;
  final String suit;
  final String imageUrl;
  final int? folderId;

  Cards({
    this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.folderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'imageUrl': imageUrl,
      'folderId': folderId,
    };
  }

  factory Cards.fromMap(Map<String, dynamic> map) {
    return Cards(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      imageUrl: map['imageUrl'],
      folderId: map['folderId'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER
      )
    ''');
  }

  // Prepopulate data
  Future<void> prepopulateData() async {
    final db = await database;
    
    // Check if folders are already populated
    final folderCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM folders')
    );
    
    if (folderCount == 0) {
      // Add the four suit folders
      final timestamp = DateTime.now().toIso8601String();
      await db.insert('folders', {'name': 'Hearts', 'timestamp': timestamp});
      await db.insert('folders', {'name': 'Spades', 'timestamp': timestamp});
      await db.insert('folders', {'name': 'Diamonds', 'timestamp': timestamp});
      await db.insert('folders', {'name': 'Clubs', 'timestamp': timestamp});
    }
    
    // Check if cards are already populated
    final cardCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards')
    );
    
    if (cardCount == 0) {
      final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
      final cardValues = [
        'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
      ];
      
      for (var suit in suits) {
        for (var value in cardValues) {
          final cardName = '$value of $suit';
          // Using a placeholder URL for the card image
          final imageUrl = 'assets/cards/${suit.toLowerCase()}_${value.toLowerCase()}.png';
          
          await db.insert('cards', {
            'name': cardName,
            'suit': suit,
            'imageUrl': imageUrl,
            'folderId': null,  // Initially, cards are not in any folder
          });
        }
      }
    }
  }

  // CRUD operations for folders
  Future<int> createFolder(Folder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await instance.database;
    final result = await db.query('folders');
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await instance.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await instance.database;
    
    // First, remove folder association from cards
    await db.update(
      'cards',
      {'folderId': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    
    // Then delete the folder
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for cards
  Future<Cards?> getCard(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Cards.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Cards>> getAllCards() async {
    final db = await instance.database;
    final result = await db.query('cards');
    return result.map((map) => Cards.fromMap(map)).toList();
  }

  Future<List<Cards>> getCardsInFolder(int folderId) async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return result.map((map) => Cards.fromMap(map)).toList();
  }

  Future<List<Cards>> getAvailableCards() async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: 'folderId IS NULL',
    );
    return result.map((map) => Cards.fromMap(map)).toList();
  }

  Future<List<Cards>> getCardsOfSuit(String suit) async {
    final db = await instance.database;
    final result = await db.query(
      'cards',
      where: 'suit = ?',
      whereArgs: [suit],
    );
    return result.map((map) => Cards.fromMap(map)).toList();
  }

  Future<int> updateCard(Cards card) async {
    final db = await instance.database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> removeCardFromFolder(int cardId) async {
    final db = await instance.database;
    return await db.update(
      'cards',
      {'folderId': null},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> addCardToFolder(int cardId, int folderId) async {
    // First, check how many cards are already in the folder
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cards WHERE folderId = ?',
        [folderId]
      )
    );
    
    if (count != null && count >= 6) {
      return -1; // Folder is full
    }
    
    return await db.update(
      'cards',
      {'folderId': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> getFolderCardCount(int folderId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cards WHERE folderId = ?',
        [folderId]
      )
    );
    return count ?? 0;
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}