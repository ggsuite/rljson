// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';

/// A simple json map
typedef Rlmap = Map<String, dynamic>;

/// Manages a normalized JSON data structure
///
/// composed of layers '@layerA', '@layerB', etc.
/// Each layer contains an _data array, which contains data items.
/// Each data item has an hash calculated using gg_json_hash.
class Rljson {
  /// Creates a new json containing the given data
  factory Rljson.fromData(Rlmap data) {
    return const Rljson._private(data: {}).addData(data);
  }

  // ...........................................................................
  /// The json data managed by this object
  final Rlmap data;

  // ...........................................................................
  /// Creates a new json containing the given data
  Rljson addData(Rlmap data) {
    _checkData(data);
    _checkLayerNames(data);
    data = addHashes(data);

    if (this.data.isEmpty) {
      return Rljson._private(data: data);
    }

    final mergedData = {...this.data};

    if (this.data.isNotEmpty) {
      for (final layer in data.keys) {
        if (layer == '_hash') {
          continue;
        }

        // Layer does not exist yet. Insert all
        final oldLayer = this.data[layer];
        final newLayer = data[layer];

        if (oldLayer == null) {
          mergedData[layer] = newLayer;
          continue;
        }

        // Layer exists. Merge data
        final mergedLayer = [...oldLayer['_data'] as List<dynamic>];
        final newData = newLayer['_data'] as List<dynamic>;

        for (final item in newData) {
          final hash = item['_hash'];
          final exists = mergedLayer.any((element) => element['_hash'] == hash);
          if (!exists) {
            mergedLayer.add(item);
          }
        }

        newLayer['_data'] = mergedLayer;
        mergedData[layer] = newLayer;
      }
    }

    return Rljson.fromData(mergedData);
  }

  // ...........................................................................
  /// Allows to query data from the json
  dynamic query({
    required String layer,
    required Map<String, dynamic> query,
  }) {
    final layerData = data[layer];
    if (layerData == null) {
      throw Exception('Layer not found: $layer');
    }

    final items = layerData['_data'] as List<dynamic>;
    return items.where((item) {
      for (final key in query.keys) {
        if (item[key] != query[key]) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ...........................................................................
  /// Returns the data at a given path
  dynamic item(String path) {
    final components = path.split('/');
    final [layer, hash, value] = components;

    final layerData = data[layer];
    if (layerData == null) {
      throw Exception('Layer not found: $layer');
    }

    final itemData = layerData['_data'].firstWhere(
      (dynamic v) => v['_hash'] == hash,
      orElse: () => null,
    );

    if (itemData == null) {
      throw Exception('Item with hash "$hash" not found.');
    }

    return itemData[value];
  }

  // ...........................................................................
  /// Returns all pathes found in data
  List<String> ls() {
    final List<String> result = [];
    for (final layer in data.keys) {
      if (layer == '_hash') {
        continue;
      }

      final layerData = data[layer];
      final items = (layerData['_data'] as List<dynamic>).cast<Rlmap>();
      for (final item in items) {
        final hash = item['_hash'];
        for (final key in item.keys) {
          if (key == '_hash') {
            continue;
          }
          result.add('$layer/$hash/$key');
        }
      }
    }
    return result;
  }

  // ...........................................................................
  /// Throws if a link is not available
  void checkLinks() {
    for (final layer in data.keys) {
      if (layer == '_hash') continue;

      for (final item
          in (data[layer]['_data'] as List<dynamic>).cast<Rlmap>()) {
        for (final key in item.keys) {
          if (key == '_hash') continue;

          if (key.startsWith('@')) {
            // Check if linked layer exists
            final linkLayer = data[key];
            final hash = item['_hash'];

            if (linkLayer == null) {
              throw Exception(
                'Layer "$layer" has an item "$hash" which links to not '
                'existing layer "$key".',
              );
            }

            // Check if linked item exists
            final targetHash = item[key];
            final linkedItem = linkLayer['_data'].firstWhere(
              (dynamic v) => v['_hash'] == targetHash,
              orElse: () => null,
            );

            if (linkedItem == null) {
              throw Exception(
                'Layer "$layer" has an item "$hash" which links to '
                'not existing item "$targetHash" in layer "$key".',
              );
            }
          }
        }
      }
    }
  }

  // ...........................................................................
  /// An example object
  static final Rljson example = Rljson.fromData({
    '@layerA': {
      '_data': [
        {
          'keyA0': 'a0',
        },
        {
          'keyA1': 'a1',
        }
      ],
    },
    '@layerB': {
      '_data': [
        {
          'keyB0': 'b0',
        },
        {
          'keyB1': 'b1',
        }
      ],
    },
  });

  // ...........................................................................
  /// An example object
  static final Rljson exampleWithLink = Rljson.fromData({
    '@layerA': {
      '_data': [
        {
          '_hash': 'KFQrf4mEz0UPmUaFHwH4T6',
          'keyA0': 'a0',
        },
        {
          '_hash': 'YPw-pxhqaUOWRFGramr4B1',
          'keyA1': 'a1',
        }
      ],
    },
    '@linkToLayerA': {
      '_data': [
        {
          '@layerA': 'KFQrf4mEz0UPmUaFHwH4T6',
        },
      ],
    },
  });

  // ######################
  // Private
  // ######################

  /// Constructor
  const Rljson._private({required this.data});

  void _checkLayerNames(Rlmap data) {
    for (final key in data.keys) {
      if (key == '_hash') continue;

      if (key.startsWith('@')) {
        continue;
      }

      throw Exception('Layer name must start with @: $key');
    }
  }

  void _checkData(Rlmap data) {
    final layersWithMissingData = <String>[];
    final layersWithWrongType = <String>[];

    for (final layer in data.keys) {
      if (layer == '_hash') continue;
      final layerData = data[layer];
      final items = layerData['_data'];
      if (items == null) {
        layersWithMissingData.add(layer);
      }

      if (items is! List<dynamic>) {
        layersWithWrongType.add(layer);
      }
    }

    if (layersWithMissingData.isNotEmpty) {
      throw Exception(
        '_data is missing in layer: ${layersWithMissingData.join(', ')}',
      );
    }

    if (layersWithWrongType.isNotEmpty) {
      throw Exception(
        '_data must be a list in layer: ${layersWithWrongType.join(', ')}',
      );
    }
  }
}
