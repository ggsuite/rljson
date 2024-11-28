# rljson

rljson: Define and Manage Relational Data Structures in JSON with Ease

![rljson](https://github.com/inlavigo/rljson/raw/main/rljson.webp)

## Motivation

Relational data structures are foundational for representing complex
relationships between entities, but traditional relational databases often
require heavy frameworks or specific query languages. By defining relational
data structures in JSON, developers gain the flexibility to work with structured
and interconnected data in a lightweight, human-readable format that's widely
supported across platforms and programming environments. `rljson` simplifies
data exchange in APIs, enhances compatibility with SQL and NoSQL databases, and
supports use cases where lightweight data representation is crucial, all while
preserving the benefits of relational modeling.

## Features

- Define independent or interconnected tables
- Link fields across tables
- Simply access to values
- Effortless data access
- Deep 128bit hashing
- Immutability, data safety and reduced redundancy

## Example

```dart
import 'package:gg_json_hash/gg_json_hash.dart' as gg_json_hash;
import 'package:rljson/rljson.dart';

Future<void> main() async {
  // .............................................................
  print('Create tables');

  var db = Rljson.fromJson({
    '@tableA': {
      '_data': [
        {'a': 'a0'},
        {'a': 'a1'},
      ],
    },
    '@tableB': {
      '_data': [
        {'b': 'b0'},
        {'b': 'b1'},
      ],
    },
  });

  // .............................................................
  print('Each item in the table gets an content based hash code');

  final hashA0 = db.hash(table: '@tableA', index: 0);
  final hashA1 = db.hash(table: '@tableA', index: 1);
  final hashB0 = db.hash(table: '@tableB', index: 0);
  final hashB1 = db.hash(table: '@tableB', index: 1);

  // .............................................................
  print('The hashcode can be used to access data');
  final a0 = db.get(table: '@tableA', item: hashA0, key1: 'a');
  print(a0); // a0

  final a1 = db.get(table: '@tableA', item: hashA1, key1: 'a');
  print(a1); // a1

  final b0 = db.get(table: '@tableB', item: hashB0, key1: 'b');
  print(b0); // b0

  final b1 = db.get(table: '@tableB', item: hashB1, key1: 'b');
  print(b1); // b1

  // .............................................................
  print('Add and merge additional data. The original table is not changed');

  final tables1 = db.addData(
    {
      '@tableA': {
        '_data': [
          {'a': 'a2'},
        ],
      },
      '@tableB': {
        '_data': [
          {'b': 'b2'},
        ],
      },
      '@tableC': {
        '_data': [
          {'c': 'c0'},
        ],
      },
    },
  );

  // .............................................................
  print('Print a list of all values in the database');
  final allPathes = tables1.ls();
  print(allPathes.map((path) => '- $path').join('\n'));

  // .............................................................
  print('Create interconnected tables');

  db = Rljson.fromJson({
    '@a': {
      '_data': [
        {
          'value': 'a',
        }
      ],
    },
  });

  final tableAValueHash = db.hash(table: '@a', index: 0);

  db = db.addData({
    '@b': {
      '_data': [
        {
          '@a': tableAValueHash,
        }
      ],
    },
  });

  final tableBValueHash = db.hash(table: '@b', index: 0);

  // .............................................................
  print('Join tables when reading values');

  final a = db.get(
    table: '@b',
    item: tableBValueHash,
    key1: '@a',
    key2: 'value',
  );

  print(a); // a

  // .............................................................
  print('To hash data in advance use gg_json_hash');
  final hashedData = gg_json_hash.addHashes({
    '@tableA': {
      '_data': [
        {'a': 'a0'},
        {'a': 'a1'},
      ],
    },
  });

  print('Validate hashes when adding data');
  db = Rljson.fromJson(hashedData, validateHashes: true);
}

```

## Contibute

Contributions are welcome! To contribute:

- Fork the repository on [GitHub](https://github.com/inlavigo/rljson.git).
- Make your changes in your forked repository.
- Submit a pull request to the main branch of this repository.
- Thank you for helping improve this package! 😊
