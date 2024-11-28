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

    group('ls()', () {
      test('lists the pathes of all items', () {
        expect(rljson.ls(), [
          '@layerA/KFQrf4mEz0UPmUaFHwH4T6/keyA0',
          '@layerA/YPw-pxhqaUOWRFGramr4B1/keyA1',
          '@layerB/nmejjLAUhygiT6WFDPPsHy/keyB0',
          '@layerB/dXhIygNwNMVPEqFbsFJkn6/keyB1',
        ]);
      });
    });

    group('fromData(data)', () {
      test('adds hashes to all fields', () {
        expect(rljson.data, {
          '@layerA': {
            'KFQrf4mEz0UPmUaFHwH4T6': {
              'keyA0': 'a0',
              '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
            },
            'YPw-pxhqaUOWRFGramr4B1': {
              'keyA1': 'a1',
              '_hash': 'YPw-pxhqaUOWRFGramr4B1',
            },
          },
          '@layerB': {
            'nmejjLAUhygiT6WFDPPsHy': {
              'keyB0': 'b0',
              '_hash': 'nmejjLAUhygiT6WFDPPsHy',
            },
            'dXhIygNwNMVPEqFbsFJkn6': {
              'keyB1': 'b1',
              '_hash': 'dXhIygNwNMVPEqFbsFJkn6',
            },
          },
        });
      });
    });

    group('layer(String layer)', () {
      group('returns', () {
        test('the layer when existing', () {
          final layer = rljson.layer('@layerA');
          expect(layer, {
            'KFQrf4mEz0UPmUaFHwH4T6': {
              'keyA0': 'a0',
              '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
            },
            'YPw-pxhqaUOWRFGramr4B1': {
              'keyA1': 'a1',
              '_hash': 'YPw-pxhqaUOWRFGramr4B1',
            },
          });
        });
      });

      group('throws', () {
        test('when layer does not exist', () {
          late final Exception exception;

          try {
            rljson.layer(
              '@layerC',
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception.toString(), 'Exception: Layer not found: @layerC');
        });
      });
    });

    group('items(layer, where)', () {
      test('returns the items that match the query', () {
        final items = rljson.items(
          layer: '@layerA',
          where: (item) => item['keyA0'] == 'a0',
        );

        expect(items, [
          {'keyA0': 'a0', '_hash': 'KFQrf4mEz0UPmUaFHwH4T6'},
        ]);
      });
    });

    group('item(layer, hash)', () {
      group('returns', () {
        test('the item when existing', () {
          final item = rljson.item('@layerA', 'KFQrf4mEz0UPmUaFHwH4T6');
          expect(item, {
            'keyA0': 'a0',
            '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
          });
        });
      });

      group('throws', () {
        test('when layer is not available', () {
          late final Exception exception;

          try {
            rljson.item('@layerC', 'KFQrf4mEz0UPmUaFHwH4T6');
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception.toString(), 'Exception: Layer not found: @layerC');
        });

        test('when hash is not available', () {
          late final Exception exception;

          try {
            rljson.item('@layerA', 'nonExistingHash');
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Item not found with hash "nonExistingHash" '
            'in layer "@layerA"',
          );
        });
      });
    });

    group('value(layer, hash, key, key2, key3, key4 followLinks)', () {
      group('returns', () {
        test('the value of the key of the item with hash in layer', () {
          expect(
            rljson.value(
              layer: '@layerA',
              itemHash: 'KFQrf4mEz0UPmUaFHwH4T6',
              key: 'keyA0',
            ),
            'a0',
          );
        });

        test('the complete item, when no key is given', () {
          expect(
            rljson.value(layer: '@layerA', itemHash: 'KFQrf4mEz0UPmUaFHwH4T6'),
            {'keyA0': 'a0', '_hash': 'KFQrf4mEz0UPmUaFHwH4T6'},
          );
        });

        test('the linked value, when property is a link', () {
          final rljson = Rljson.exampleWithLink;

          expect(
            rljson.value(
              layer: '@linkToLayerA',
              itemHash: 'Cr5kvgDz5NGgbnuHu-Z05N',
              key: '@layerA',
            ),
            {'_hash': 'KFQrf4mEz0UPmUaFHwH4T6', 'keyA0': 'a0'},
          );
        });

        test('the linked value accross multiple layers using key2 to key4', () {
          final rljson = Rljson.exampleWithDeepLink;
          // print(const JsonEncoder.withIndent(' ')
          // .convert(rljson.originalData));
          // return;
          expect(
            rljson.value(
              layer: '@a',
              itemHash: 'GnSVp1CmoAo3rPiiGl44p-',
              key: '@b',
              key2: '@c',
              key3: '@d',
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
            rljson.value(
              layer: '@layerA',
              itemHash: 'KFQrf4mEz0UPmUaFHwH4T6',
              key: 'nonExistingKey',
            );
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Key "nonExistingKey" not found in item with hash '
            '"KFQrf4mEz0UPmUaFHwH4T6" in layer "@layerA"',
          );
        });

        test('when a second key is given but the first key is not a link', () {
          late final Exception exception;

          try {
            rljson.value(
              layer: '@layerA',
              itemHash: 'KFQrf4mEz0UPmUaFHwH4T6',
              key: 'keyA0',
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
        test('when layer names do not start with @', () {
          late final Exception exception;

          try {
            rljson.addData({
              'layerA': {'_data': <dynamic>[]},
              'layerB': {'_data': <dynamic>[]},
              'layerC': {'_data': <dynamic>[]},
            });
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: Layer name must start with @: layerA',
          );
        });

        test('when layers do not contain a _data object', () {
          late final Exception exception;

          try {
            rljson.addData({
              '@layerA': <String, dynamic>{},
              '@layerB': <String, dynamic>{},
            });
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: _data is missing in layer: @layerA, @layerB',
          );
        });

        test('when layers do not contain a _data that is not a list', () {
          late final Exception exception;

          try {
            rljson.addData({
              '@layerA': <String, dynamic>{
                '_data': <dynamic>{},
              },
              '@layerB': <String, dynamic>{
                '_data': <dynamic>{},
              },
            });
          } catch (e) {
            exception = e as Exception;
          }

          expect(
            exception.toString(),
            'Exception: '
            '_data must be a list in layer: @layerA, @layerB',
          );
        });
      });

      test('adds data to the json', () {
        final rljson2 = rljson.addData({
          '@layerA': {
            '_data': [
              {'keyA2': 'a2'},
            ],
          },
        });

        final items = rljson2.originalData['@layerA']['_data'] as List<dynamic>;
        expect(items, [
          {'keyA0': 'a0', '_hash': 'KFQrf4mEz0UPmUaFHwH4T6'},
          {'keyA1': 'a1', '_hash': 'YPw-pxhqaUOWRFGramr4B1'},
          {'keyA2': 'a2', '_hash': 'apLP3I2XLnVm13umIZdVhV'},
        ]);
      });

      test('replaces data when the added layer is not yet existing', () {
        final rljson2 = rljson.addData({
          '@layerC': {
            '_data': [
              {'keyC0': 'c0'},
            ],
          },
        });

        final items = rljson2.ls();
        expect(items, [
          '@layerA/KFQrf4mEz0UPmUaFHwH4T6/keyA0',
          '@layerA/YPw-pxhqaUOWRFGramr4B1/keyA1',
          '@layerB/nmejjLAUhygiT6WFDPPsHy/keyB0',
          '@layerB/dXhIygNwNMVPEqFbsFJkn6/keyB1',
          '@layerC/afNjjrfH8-OfkkEH1uCK14/keyC0',
        ]);
      });

      test('does not cause duplicates', () {
        final rljson2 = rljson.addData({
          '@layerA': {
            '_data': [
              {'keyA1': 'a1'},
            ],
          },
        });

        final items = rljson2.originalData['@layerA']['_data'] as List<dynamic>;
        expect(items, [
          {'keyA0': 'a0', '_hash': 'KFQrf4mEz0UPmUaFHwH4T6'},
          {'keyA1': 'a1', '_hash': 'YPw-pxhqaUOWRFGramr4B1'},
        ]);
      });
    });

    group('checkLinks()', () {
      test('does nothing when all links are ok', () {
        final rljson = Rljson.exampleWithLink;
        rljson.checkLinks();
      });

      group('throws', () {
        test('when the layer of a link does not exist', () {
          final rljson = Rljson.exampleWithLink;

          // Add an item with an link to a non-existing layer
          final jsonWithBrokenLink = rljson.addData({
            '@layerA': {
              '_data': [
                {
                  '@nonExistingLayer': 'a2',
                },
              ],
            },
          });

          late final String message;

          try {
            jsonWithBrokenLink.checkLinks();
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            'Exception: Layer "@layerA" has an item "isQfTSg24p0hXHxkBB_wEa" '
            'which links to not existing layer "@nonExistingLayer".',
          );
        });

        test('when linked item does not exist', () {
          final rljson = Rljson.exampleWithLink;

          // Add an item with an link to a non-existing layer
          final jsonWithBrokenLink = rljson.addData({
            '@linkToLayerA': {
              '_data': [
                {
                  '@layerA': 'brokenHash',
                },
              ],
            },
          });

          late final String message;

          try {
            jsonWithBrokenLink.checkLinks();
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            'Exception: Layer "@linkToLayerA" has an item '
            '"NnQGoODqzFIwANtgDUMkhA" which links to not existing '
            'item "brokenHash" in layer "@layerA".',
          );
        });
      });
    });

    group('data', () {
      group('returns the data where the _data list is replaced by a map', () {
        test('with example', () {
          expect(rljson.data, <String, dynamic>{
            '@layerA': {
              'KFQrf4mEz0UPmUaFHwH4T6': {
                'keyA0': 'a0',
                '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
              },
              'YPw-pxhqaUOWRFGramr4B1': {
                'keyA1': 'a1',
                '_hash': 'YPw-pxhqaUOWRFGramr4B1',
              },
            },
            '@layerB': {
              'nmejjLAUhygiT6WFDPPsHy': {
                'keyB0': 'b0',
                '_hash': 'nmejjLAUhygiT6WFDPPsHy',
              },
              'dXhIygNwNMVPEqFbsFJkn6': {
                'keyB1': 'b1',
                '_hash': 'dXhIygNwNMVPEqFbsFJkn6',
              },
            },
          });
        });

        test('with added data', () {
          final rljson2 = rljson.addData({
            '@layerC': {
              '_data': [
                {'keyC0': 'c0'},
              ],
            },
          });

          expect(rljson2.data, {
            '@layerA': {
              'KFQrf4mEz0UPmUaFHwH4T6': {
                'keyA0': 'a0',
                '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
              },
              'YPw-pxhqaUOWRFGramr4B1': {
                'keyA1': 'a1',
                '_hash': 'YPw-pxhqaUOWRFGramr4B1',
              },
            },
            '@layerB': {
              'nmejjLAUhygiT6WFDPPsHy': {
                'keyB0': 'b0',
                '_hash': 'nmejjLAUhygiT6WFDPPsHy',
              },
              'dXhIygNwNMVPEqFbsFJkn6': {
                'keyB1': 'b1',
                '_hash': 'dXhIygNwNMVPEqFbsFJkn6',
              },
            },
            '@layerC': {
              'afNjjrfH8-OfkkEH1uCK14': {
                'keyC0': 'c0',
                '_hash': 'afNjjrfH8-OfkkEH1uCK14',
              },
            },
          });
        });
      });
    });
  });
}
