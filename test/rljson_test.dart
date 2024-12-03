// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:rljson/rljson.dart';
import 'package:test/test.dart';

void main() {
  group('Rljson', () {
    final rljson = Rljson.example;
    late String a0Hash;
    late String a1Hash;
    late String b0Hash;
    late String b1Hash;

    setUp(
      () {
        a0Hash = rljson.hash(table: 'tableA', index: 0);
        a1Hash = rljson.hash(table: 'tableA', index: 1);
        b0Hash = rljson.hash(table: 'tableB', index: 0);
        b1Hash = rljson.hash(table: 'tableB', index: 1);

        expect(a0Hash.length, 22);
        expect(a1Hash.length, 22);
        expect(b0Hash.length, 22);
        expect(b1Hash.length, 22);
      },
    );

    group('ls()', () {
      test('lists the pathes of all items', () {
        expect(rljson.ls(), [
          'tableA/KFQrf4mEz0UPmUaFHwH4T6/keyA0',
          'tableA/YPw-pxhqaUOWRFGramr4B1/keyA1',
          'tableB/nmejjLAUhygiT6WFDPPsHy/keyB0',
          'tableB/dXhIygNwNMVPEqFbsFJkn6/keyB1',
        ]);
      });
    });

    group('fromData(data)', () {
      test('adds hashes to all fields', () {
        expect(rljson.data, {
          'tableA': {
            a0Hash: {
              'keyA0': 'a0',
              '_hash': a0Hash,
            },
            a1Hash: {
              'keyA1': 'a1',
              '_hash': a1Hash,
            },
          },
          'tableB': {
            b0Hash: {
              'keyB0': 'b0',
              '_hash': b0Hash,
            },
            b1Hash: {
              'keyB1': 'b1',
              '_hash': b1Hash,
            },
          },
        });
      });
    });

    group('table(String table)', () {
      group('returns', () {
        test('the table when existing', () {
          final table = rljson.table('tableA');
          expect(table, {
            a0Hash: {
              'keyA0': 'a0',
              '_hash': a0Hash,
            },
            a1Hash: {
              'keyA1': 'a1',
              '_hash': a1Hash,
            },
          });
        });
      });

      group('throws', () {
        test('when table does not exist', () {
          late final Exception exception;

          try {
            rljson.table(
              'tableC',
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception.toString(), 'Exception: Table not found: tableC');
        });
      });
    });

    group('items(table, where)', () {
      test('returns the items that match the query', () {
        final items = rljson.items(
          table: 'tableA',
          where: (item) => item['keyA0'] == 'a0',
        );

        expect(items, [
          {'keyA0': 'a0', '_hash': a0Hash},
        ]);
      });
    });

    group('item(table, hash)', () {
      group('returns', () {
        test('the item when existing', () {
          final item = rljson.item('tableA', a0Hash);
          expect(item, {
            'keyA0': 'a0',
            '_hash': a0Hash,
          });
        });
      });

      group('throws', () {
        test('when table is not available', () {
          late final Exception exception;

          try {
            rljson.item('tableC', a0Hash);
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception.toString(), 'Exception: Table not found: tableC');
        });

        test('when hash is not available', () {
          late final Exception exception;

          try {
            rljson.item('tableA', 'nonExistingHash');
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Item not found with hash "nonExistingHash" '
            'in table "tableA"',
          );
        });
      });
    });

    group('value(table, hash, key, key2, key3, key4 followLinks)', () {
      group('returns', () {
        test('the value of the key of the item with hash in table', () {
          expect(
            rljson.get(
              table: 'tableA',
              item: a0Hash,
              key1: 'keyA0',
            ),
            'a0',
          );
        });

        test('the complete item, when no key is given', () {
          expect(
            rljson.get(table: 'tableA', item: a0Hash),
            {'keyA0': 'a0', '_hash': a0Hash},
          );
        });

        test('the linked value, when property is a link', () {
          final rljson = Rljson.exampleWithLink;

          final tableALinkHash = rljson.hash(table: 'linkToTableA', index: 0);

          expect(
            rljson.get(
              table: 'linkToTableA',
              item: tableALinkHash,
              key1: 'tableARef',
            ),
            {'_hash': a0Hash, 'keyA0': 'a0'},
          );
        });

        test('the linked value accross multiple tables using key2 to key4', () {
          final rljson = Rljson.exampleWithDeepLink;
          final hash = (rljson.data['a'] as Map<String, dynamic>).keys.first;
          // print(const JsonEncoder.withIndent(' ')
          // .convert(rljson.originalData));
          // return;
          expect(
            rljson.get(
              table: 'a',
              item: hash,
              key1: 'bRef',
              key2: 'cRef',
              key3: 'dRef',
              key4: 'value',
            ),
            'd',
          );
        });
      });

      group('throws', () {
        test('when key does not point to a valid value', () {
          late final Exception exception;

          try {
            rljson.get(
              table: 'tableA',
              item: a0Hash,
              key1: 'nonExistingKey',
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Key "nonExistingKey" not found in item with hash '
            '"KFQrf4mEz0UPmUaFHwH4T6" in table "tableA"',
          );
        });

        test('when a second key is given but the first key is not a link', () {
          late final Exception exception;

          try {
            rljson.get(
              table: 'tableA',
              item: a0Hash,
              key1: 'keyA0',
              key2: 'keyA1',
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Invalid key "keyA1". '
            'Additional keys are only allowed for links. '
            'But key "keyA0" points to a value.',
          );
        });
      });
    });

    group('addData(data)', () {
      group('throws', () {
        test('when validateHashes is true and hashes are missing', () {
          late final Exception exception;

          try {
            rljson.addData(
              {
                'tableA': {
                  '_data': [
                    {'keyA0': 'a0'},
                  ],
                },
              },
              validateHashes: true,
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Hash is missing.',
          );
        });

        test('when tables do not contain a _data object', () {
          late final Exception exception;

          try {
            rljson.addData({
              'tableA': <String, dynamic>{},
              'tableB': <String, dynamic>{},
            });
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: _data is missing in table: tableA, tableB',
          );
        });

        test('when tables do not contain a _data that is not a list', () {
          late final Exception exception;

          try {
            rljson.addData({
              'tableA': <String, dynamic>{
                '_data': <dynamic>{},
              },
              'tableB': <String, dynamic>{
                '_data': <dynamic>{},
              },
            });
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: '
            '_data must be a list in table: tableA, tableB',
          );
        });
      });

      test('adds data to the json', () {
        final rljson2 = rljson.addData({
          'tableA': {
            '_data': [
              {'keyA2': 'a2'},
            ],
          },
        });

        final items = rljson2.originalData['tableA']['_data'] as List<dynamic>;
        expect(items, [
          {'keyA0': 'a0', '_hash': a0Hash},
          {'keyA1': 'a1', '_hash': a1Hash},
          {'keyA2': 'a2', '_hash': 'apLP3I2XLnVm13umIZdVhV'},
        ]);
      });

      test('replaces data when the added table is not yet existing', () {
        final rljson2 = rljson.addData({
          'tableC': {
            '_data': [
              {'keyC0': 'c0'},
            ],
          },
        });

        final items = rljson2.ls();
        expect(items, [
          'tableA/KFQrf4mEz0UPmUaFHwH4T6/keyA0',
          'tableA/YPw-pxhqaUOWRFGramr4B1/keyA1',
          'tableB/nmejjLAUhygiT6WFDPPsHy/keyB0',
          'tableB/dXhIygNwNMVPEqFbsFJkn6/keyB1',
          'tableC/afNjjrfH8-OfkkEH1uCK14/keyC0',
        ]);
      });

      test('does not cause duplicates', () {
        final rljson2 = rljson.addData({
          'tableA': {
            '_data': [
              {'keyA1': 'a1'},
            ],
          },
        });

        final items = rljson2.originalData['tableA']['_data'] as List<dynamic>;
        expect(items, [
          {'keyA0': 'a0', '_hash': a0Hash},
          {'keyA1': 'a1', '_hash': a1Hash},
        ]);
      });
    });

    group('checkLinks()', () {
      test('does nothing when all links are ok', () {
        final rljson = Rljson.exampleWithLink;
        rljson.checkLinks();
      });

      group('throws', () {
        test('when the table of a link does not exist', () {
          final rljson = Rljson.exampleWithLink;

          // Add an item with an link to a non-existing table
          final jsonWithBrokenLink = rljson.addData({
            'tableA': {
              '_data': [
                {
                  'nonExistingTableRef': 'a2',
                },
              ],
            },
          });

          final a0Hash = jsonWithBrokenLink.hash(table: 'tableA', index: 2);

          late final String message;

          try {
            jsonWithBrokenLink.checkLinks();
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            'Exception: Table "tableA" has an item "$a0Hash" '
            'which links to not existing table "nonExistingTable".',
          );
        });

        test('when linked item does not exist', () {
          final rljson = Rljson.exampleWithLink;

          // Add an item with an link to a non-existing table
          final jsonWithBrokenLink = rljson.addData({
            'linkToTableA': {
              '_data': [
                {
                  'tableARef': 'brokenHash',
                },
              ],
            },
          });

          final linkToTableAHash = jsonWithBrokenLink.hash(
            table: 'linkToTableA',
            index: 1,
          );

          late final String message;

          try {
            jsonWithBrokenLink.checkLinks();
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            'Exception: Table "linkToTableA" has an item '
            '"$linkToTableAHash" which links to not existing '
            'item "brokenHash" in table "tableA".',
          );
        });
      });
    });

    group('data', () {
      group('returns the data where the _data list is replaced by a map', () {
        test('with example', () {
          expect(rljson.data, <String, dynamic>{
            'tableA': {
              a0Hash: {
                'keyA0': 'a0',
                '_hash': a0Hash,
              },
              a1Hash: {
                'keyA1': 'a1',
                '_hash': a1Hash,
              },
            },
            'tableB': {
              b0Hash: {
                'keyB0': 'b0',
                '_hash': b0Hash,
              },
              b1Hash: {
                'keyB1': 'b1',
                '_hash': b1Hash,
              },
            },
          });
        });

        test('with added data', () {
          final rljson2 = rljson.addData({
            'tableC': {
              '_data': [
                {'keyC0': 'c0'},
              ],
            },
          });

          expect(rljson2.data, {
            'tableA': {
              a0Hash: {
                'keyA0': 'a0',
                '_hash': a0Hash,
              },
              a1Hash: {
                'keyA1': 'a1',
                '_hash': a1Hash,
              },
            },
            'tableB': {
              b0Hash: {
                'keyB0': 'b0',
                '_hash': b0Hash,
              },
              b1Hash: {
                'keyB1': 'b1',
                '_hash': b1Hash,
              },
            },
            'tableC': {
              'afNjjrfH8-OfkkEH1uCK14': {
                'keyC0': 'c0',
                '_hash': 'afNjjrfH8-OfkkEH1uCK14',
              },
            },
          });
        });
      });
    });

    group('hash(table, index)', () {
      group('returns', () {
        test('the hash of the item at the index of the table', () {
          expect(rljson.hash(table: 'tableA', index: 0), a0Hash);
          expect(rljson.hash(table: 'tableA', index: 1), a1Hash);
          expect(rljson.hash(table: 'tableB', index: 0), b0Hash);
          expect(rljson.hash(table: 'tableB', index: 1), b1Hash);
        });
      });

      group('throws', () {
        test('when table does not exist', () {
          late final Exception exception;

          try {
            rljson.hash(table: 'tableC', index: 0);
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception.toString(), 'Exception: Table "tableC" not found.');
        });

        test('when index is out of range', () {
          late final Exception exception;

          try {
            rljson.hash(table: 'tableA', index: 2);
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Index 2 out of range in table "tableA".',
          );
        });
      });
    });

    group('checkTableNames(data)', () {
      test(
          'throws when table names contain other chars then letters '
          'and numbers', () {
        late final String exception;

        try {
          Rljson.checkTableNames({
            'tableA/': <String, dynamic>{},
          });
        } catch (e) {
          exception = e.toString();
        }

        expect(
          exception.toString(),
          'Exception: Invalid table name: tableA/. Only letters and numbers '
          'are allowed.',
        );
      });

      test('throws when table names end with Ref', () {
        late final String exception;

        try {
          Rljson.checkTableNames({
            'tableARef': <String, dynamic>{},
          });
        } catch (e) {
          exception = e.toString();
        }

        expect(
          exception.toString(),
          'Exception: Invalid table name: tableARef. Table names must not end '
          'with "Ref".',
        );
      });

      test('throws when table names start with numbers', () {
        late final String exception;

        try {
          Rljson.checkTableNames({
            '5tableA': <String, dynamic>{},
          });
        } catch (e) {
          exception = e.toString();
        }

        expect(
          exception.toString(),
          'Exception: Invalid table name: 5tableA. Table names must not start '
          'with a number.',
        );
      });
    });
  });
}
