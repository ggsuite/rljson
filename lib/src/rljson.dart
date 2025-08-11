// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';

/// A simple json map
typedef Rlmap = Map<String, dynamic>;

/// A map of tables
typedef Rltables = Map<String, Rlmap>;

/// Manages a normalized JSON data structure
///
/// composed of tables 'tableA', 'tableB', etc.
/// Each table contains an _data array, which contains data items.
/// Each data item has an hash calculated using gg_json_hash.
class Rljson {
  /// Creates a new json containing the given data
  factory Rljson.fromJson(Rlmap data, {bool validateHashes = false}) {
    return const Rljson._private(
      originalData: {},
      data: {},
    ).addData(data, validateHashes: validateHashes);
  }

  // ...........................................................................
  /// The json data managed by this object
  final Rlmap originalData;

  /// Returns a map of tables containing a map of items for fast access
  final Rltables data;

  /// Used JsonHash instance
  final jh = JsonHash.defaultInstance;

  // ...........................................................................
  /// Creates a new json containing the given data
  Rljson addData(Rlmap addedData, {bool validateHashes = false}) {
    _checkData(addedData);
    checkTableNames(addedData);

    if (validateHashes) {
      jh.validate(addedData);
    }

    addedData = jh.apply(addedData);
    final addedDataAsMap = _toMap(addedData);

    if (originalData.isEmpty) {
      return Rljson._private(originalData: addedData, data: addedDataAsMap);
    }

    final mergedData = {...originalData};
    final mergedMap = {...data};

    if (originalData.isNotEmpty) {
      for (final table in addedData.keys) {
        if (table == '_hash') {
          continue;
        }

        final oldTable = originalData[table];
        final newTable = addedData[table];

        // Table does not exist yet. Insert all
        if (oldTable == null) {
          mergedData[table] = newTable;
          mergedMap[table] = addedDataAsMap[table]!;
          continue;
        }

        final oldMap = data[table] as Rlmap;

        // Table exists. Merge data
        final mergedTableData = [...oldTable['_data'] as List<dynamic>];
        final mergedTableMap = {...oldMap};
        final newData = newTable['_data'] as List<dynamic>;

        for (final item in newData) {
          final hash = item['_hash'] as String;
          final exists = mergedTableMap[hash] != null;

          if (!exists) {
            mergedTableData.add(item);
            mergedTableMap[hash] = item;
          }
        }

        newTable['_data'] = mergedTableData;
        mergedData[table] = newTable;
        mergedMap[table] = mergedTableMap;
      }
    }

    return Rljson._private(originalData: mergedData, data: mergedMap);
  }

  // ...........................................................................
  /// Returns the table with the given name. Throws when name is not found.
  Rltables table(String table) {
    final tableData = data[table] as Rltables?;
    if (tableData == null) {
      throw Exception('Table not found: $table');
    }

    return tableData;
  }

  // ...........................................................................
  /// Allows to query data from the json
  List<Rlmap> items({
    required String table,
    required bool Function(Rlmap item) where,
  }) {
    final tableData = this.table(table);
    final items = tableData.values.where(where).toList();
    return items;
  }

  // ...........................................................................
  /// Allows to query data from the json
  Rlmap item(String table, String hash) {
    // Get table
    final tableData = data[table];
    if (tableData == null) {
      throw Exception('Table not found: $table');
    }

    // Get item
    final item = tableData[hash] as Rlmap?;
    if (item == null) {
      throw Exception('Item not found with hash "$hash" in table "$table"');
    }

    return item;
  }

  // ...........................................................................
  /// Queries a value from data. Throws when table or hash is not found.
  dynamic get({
    required String table,
    required String item,
    String? key1,
    String? key2,
    String? key3,
    String? key4,
  }) {
    // Get item
    final itemHash = item;
    final resultItem = this.item(table, itemHash);

    // If no key is given, return the complete item
    if (key1 == null) {
      return resultItem;
    }

    // Get item value
    final itemValue = resultItem[key1];
    if (itemValue == null) {
      throw Exception(
        'Key "$key1" not found in item with hash "$itemHash" in table "$table"',
      );
    }

    // Return item value when no link or links are not followed
    if (!key1.endsWith('Ref')) {
      if (key2 != null) {
        throw Exception(
          'Invalid key "$key2". Additional keys are only allowed for links. '
          'But key "$key1" points to a value.',
        );
      }

      return itemValue;
    }

    // Follow links
    final targetTable = key1.substring(0, key1.length - 3);
    final targetHash = itemValue as String;

    return get(
      table: targetTable,
      item: targetHash,
      key1: key2,
      key2: key3,
      key3: key4,
    );
  }

  // ...........................................................................
  /// Returns the hash of the item at the given index in the table
  String hash({required String table, required int index}) {
    final tableData = originalData[table] as Rlmap?;

    if (tableData == null) {
      throw Exception('Table "$table" not found.');
    }

    final items = tableData['_data'] as List<dynamic>;
    if (index >= items.length) {
      throw Exception('Index $index out of range in table "$table".');
    }

    final item = items[index] as Rlmap;
    return item['_hash'] as String;
  }

  // ...........................................................................
  /// Returns all pathes found in data
  List<String> ls() {
    final List<String> result = [];
    for (final tableEntry in data.entries) {
      final table = tableEntry.key;
      final tableData = tableEntry.value;

      for (final itemEntry in tableData.entries) {
        final item = itemEntry.value as Rlmap;
        final hash = item['_hash'];
        for (final key in item.keys) {
          if (key == '_hash') {
            continue;
          }
          result.add('$table/$hash/$key');
        }
      }
    }
    return result;
  }

  // ...........................................................................
  /// Throws if a link is not available
  void checkLinks() {
    for (final table in data.keys) {
      final tableData = data[table] as Rlmap;

      for (final entry in tableData.entries) {
        final item = entry.value as Rlmap;
        for (final key in item.keys) {
          if (key == '_hash') continue;

          if (key.endsWith('Ref')) {
            final tableName = key.substring(0, key.length - 3);
            // Check if linked table exists
            final linkTable = data[tableName];
            final hash = item['_hash'];

            if (linkTable == null) {
              throw Exception(
                'Table "$table" has an item "$hash" which links to not '
                'existing table "$tableName".',
              );
            }

            // Check if linked item exists
            final targetHash = item[key];
            final linkedItem = linkTable[targetHash];

            if (linkedItem == null) {
              throw Exception(
                'Table "$table" has an item "$hash" which links to '
                'not existing item "$targetHash" in table "$tableName".',
              );
            }
          }
        }
      }
    }
  }

  // ...........................................................................
  /// An example object
  static final Rljson example = Rljson.fromJson({
    'tableA': {
      '_data': [
        {'keyA0': 'a0'},
        {'keyA1': 'a1'},
      ],
    },
    'tableB': {
      '_data': [
        {'keyB0': 'b0'},
        {'keyB1': 'b1'},
      ],
    },
  });

  // ...........................................................................
  /// An example object
  static final Rljson exampleWithLink = Rljson.fromJson({
    'tableA': {
      '_data': [
        {'keyA0': 'a0'},
        {'keyA1': 'a1'},
      ],
    },
    'linkToTableA': {
      '_data': [
        {'tableARef': 'KFQrf4mEz0UPmUaFHwH4T6'},
      ],
    },
  });

  /// An example object are tables are linked a -> b -> c -> d
  static Rljson get exampleWithDeepLink {
    // Create an Rljson instance
    var rljson = Rljson.fromJson({});

    // Create a table d
    rljson = rljson.addData({
      'd': {
        '_data': [
          {'value': 'd'},
        ],
      },
    });

    // Get the hash of d
    final hashD = rljson.hash(table: 'd', index: 0);

    // Create a second table c linking to d
    rljson = rljson.addData({
      'c': {
        '_data': [
          {'dRef': hashD, 'value': 'c'},
        ],
      },
    });

    // Get the hash of c
    final hashC = rljson.hash(table: 'c', index: 0);

    // Create a third table b linking to c
    rljson = rljson.addData({
      'b': {
        '_data': [
          {'cRef': hashC, 'value': 'b'},
        ],
      },
    });

    // Get the hash of b
    final hashB = rljson.hash(table: 'b', index: 0);

    // Create a first table a linking to b
    rljson = rljson.addData({
      'a': {
        '_data': [
          {'bRef': hashB, 'value': 'a'},
        ],
      },
    });

    return rljson;
  }

  // ...........................................................................
  /// Checks if table names in data are valid
  static void checkTableNames(Rlmap data) {
    for (final key in data.keys) {
      if (key == '_hash') continue;
      checkTableName(key);
    }
  }

  // ...........................................................................
  /// Checks if a string is valid table name
  static void checkTableName(String str) {
    // Table name must only contain letters and numbers.
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(str)) {
      throw Exception(
        'Invalid table name: $str. Only letters and numbers are allowed.',
      );
    }

    // Table names must not end with Ref
    if (str.endsWith('Ref')) {
      throw Exception(
        'Invalid table name: $str. Table names must not end with "Ref".',
      );
    }

    // Table names must not start with a number
    if (RegExp(r'^[0-9]').hasMatch(str)) {
      throw Exception(
        'Invalid table name: $str. Table names must not start with a number.',
      );
    }
  }

  // ######################
  // Private
  // ######################

  /// Constructor
  const Rljson._private({required this.originalData, required this.data});

  // ...........................................................................
  void _checkData(Rlmap data) {
    final tablesWithMissingData = <String>[];
    final tablesWithWrongType = <String>[];

    for (final table in data.keys) {
      if (table == '_hash') continue;
      final tableData = data[table];
      final items = tableData['_data'];
      if (items == null) {
        tablesWithMissingData.add(table);
      }

      if (items is! List<dynamic>) {
        tablesWithWrongType.add(table);
      }
    }

    if (tablesWithMissingData.isNotEmpty) {
      throw Exception(
        '_data is missing in table: ${tablesWithMissingData.join(', ')}',
      );
    }

    if (tablesWithWrongType.isNotEmpty) {
      throw Exception(
        '_data must be a list in table: ${tablesWithWrongType.join(', ')}',
      );
    }
  }

  // ...........................................................................
  Rltables _toMap(Rlmap data) {
    final result = <String, Rlmap>{};

    // Iterate all tables
    for (final table in data.keys) {
      if (table.startsWith('_')) continue;

      final tableData = <String, Rlmap>{};
      result[table] = tableData;

      // Turn _data into map
      final items = data[table]['_data'] as List<dynamic>;

      for (final item in items) {
        final hash = item['_hash'] as String;
        tableData[hash] = item as Rlmap;
      }
    }

    return result;
  }
}
