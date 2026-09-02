// Placed by `helix init` — instantiates and verifies this project's DNA
// on every test run. The logic lives in the helix dev-dependency and is
// updated through normal dependency updates.

import 'package:helix/helix.dart';
import 'package:test/test.dart';

void main() {
  test(
    'dna is instantiated and unmodified',
    () => runDnaTest(),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
