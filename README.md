# buuid - Better UUID

Create and handle UUID.

## Usage

Add the dependency to your pubspec.yaml.

```yaml
dependencies:
  buuid: ^0.1.0
```

Then import the library and use it.

```dart
import 'package:buuid/buuid.dart';

main() {
  final uuid1 = UUID();
  final uuid2 = UUID.parse(uuid1.toString());
  print('${uuid1 == uuid2}');
}
```

Output
```bash
true
```

## Credit

This package is a Dart port from the Go package [https://github.com/google/uuid].
