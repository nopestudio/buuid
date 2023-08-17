part of buuid;

// import 'util.dart';
// import 'dce.dart';

// Package uuid generates and inspects UUIDs.
//
// UUIDs are based on RFC 4122 and DCE 1.1: Authentication and Security
// Services.
//
// A UUID is a 16 byte (128 bit) array.  UUIDs may be used as keys to
// maps or compared directly.

// Constants returned by Variant.
enum Variant {
  Invalid, // Invalid UUID
  RFC4122, // The variant specified in RFC4122
  Reserved, // Reserved, NCS backward compatibility.
  Microsoft, // Reserved, Microsoft Corporation backward compatibility.
  Future, // Reserved for future definition.
}

const randPoolSize = 16 * 16;

var rander = Random.secure(); // random function
var poolEnabled = false;
// poolMu      sync.Mutex
var poolPos = randPoolSize; // protected with poolMu
var pool = Uint8List(randPoolSize); // protected with poolMu

class InvalidLengthException implements Exception {
  final int len;

  const InvalidLengthException(this.len);

  String errMsg() => 'invalid UUID length: $len';
}

// A UUID is a 128 bit (16 byte) Universal Unique IDentifier as defined in RFC
// 4122.
class UUID {
  final Uint8List bytes;

  // UUID returns a Random (Version 4) UUID.
  //
  // The strength of the UUIDs is based on the strength of the crypto/rand
  // package.
  //
  // Uses the randomness pool if it was enabled with EnableRandPool.
  //
  // A note about uniqueness derived from the UUID Wikipedia entry:
  //
  //  Randomly generated UUIDs have 122 random bits.  One's annual risk of being
  //  hit by a meteorite is estimated to be one chance in 17 billion, that
  //  means the probability is about 0.00000000006 (6 × 10−11),
  //  equivalent to the odds of creating a few tens of trillions of UUIDs in a
  //  year and having one duplicate.
  factory UUID() {
    if (!poolEnabled) {
      return UUID._newRandomFromRander(rander);
    }
    return UUID._newRandomFromPool();
  }

  factory UUID.fromJson(String json) {
    return UUID.parse(json);
  }

  String toJson() => toString();

  factory UUID._newRandomFromRander(Random r) {
    final b = Uint8List(16);
    for (var i = 0; i < b.length; i++) {
      b[i] = r.nextInt(256);
    }
    b[6] = (b[6] & 0x0f) | 0x40; // Version 4
    b[8] = (b[8] & 0x3f) | 0x80; // Variant is 10
    return UUID.fromBytes(b);
  }

  factory UUID._newRandomFromPool() {
    if (poolPos == randPoolSize) {
      for (var i = 0; i < pool.length; i++) {
        pool[i] = rander.nextInt(256);
      }
      poolPos = 0;
    }
    final b = pool.sublist(poolPos, poolPos + 16);
    poolPos += 16;

    b[6] = (b[6] & 0x0f) | 0x40; // Version 4
    b[8] = (b[8] & 0x3f) | 0x80; // Variant is 10
    return UUID.fromBytes(b);
  }

  // fromBytes creates a new UUID from a byte list. Throws an error if the slice
  // does not have a length of 16. The bytes are copied from the list.
  UUID.fromBytes(this.bytes) {
    if (bytes.length != 16) {
      throw InvalidLengthException(bytes.length);
    }
  }

  factory UUID.parse(String s) {
    final bytes = Uint8List(16);

    switch (s.length) {
      // xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      case 36:
        break;
      // urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      case 36 + 9:
        if (s.substring(0, 9).toLowerCase() != 'urn:uuid:') {
          throw Exception('invalid urn prefix: ${s.substring(0, 9)}');
        }
        s = s.substring(9);
        break;
      // {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
      case 36 + 2:
        s = s.substring(1);
        break;
      // xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      case 32:
        for (var i = 0; i < bytes.length; i++) {
          final res = xtob(s.codeUnitAt(i * 2), s.codeUnitAt(i * 2 + 1));
          if (!res.item2) {
            throw Exception('invalid UUID format');
          }
          bytes[i] = res.item1;
        }
        return UUID.fromBytes(bytes);
      default:
        throw InvalidLengthException(s.length);
    }

    // s is now at least 36 bytes long
    // it must be of the form  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    if (s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-') {
      throw Exception('invalid UUID format');
    }
    final range = <int>[
      0,
      2,
      4,
      6,
      9,
      11,
      14,
      16,
      19,
      21,
      24,
      26,
      28,
      30,
      32,
      34,
    ];
    for (var i = 0; i < range.length; i++) {
      final x = range[i];
      final res = xtob(s.codeUnitAt(x), s.codeUnitAt(x + 1));
      if (!res.item2) {
        throw Exception('invalid UUID format');
      }
      bytes[i] = res.item1;
    }
    return UUID.fromBytes(bytes);
  }

  // String returns the string form of uuid, xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  // , or "" if uuid is invalid.
  @override
  String toString() {
    return utf8.decode(encodeHex());
  }

  // URN returns the RFC 2141 URN form of uuid,
  // urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,  or "" if uuid is invalid.
  String URN() {
    return 'urn:uuid:' + utf8.decode(encodeHex());
  }

  Uint8List encodeHex() {
    return Uint8List.fromList(
      ([
        hex.encode(bytes.sublist(0, 4)),
        hex.encode(bytes.sublist(4, 6)),
        hex.encode(bytes.sublist(6, 8)),
        hex.encode(bytes.sublist(8, 10)),
        hex.encode(bytes.sublist(10)),
      ].join('-'))
          .codeUnits,
    );
  }

  @override
  bool operator ==(o) => o is UUID && ListEquality().equals(bytes, o.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);

  // variant returns the variant encoded in uuid.
  Variant get variant {
    if ((bytes[8] & 0xc0) == 0x80) {
      return Variant.RFC4122;
    } else if ((bytes[8] & 0xe0) == 0xc0) {
      return Variant.Microsoft;
    } else if ((bytes[8] & 0xe0) == 0xe0) {
      return Variant.Future;
    }
    return Variant.Reserved;
  }

  // Version returns the version of uuid.
  Version get version {
    return bytes[6] >> 4;
  }

  // withDCESecurity returns a DCE Security (Version 2) UUID.
  //
  // The domain should be one of Person, Group or Org.
  // On a POSIX system the id should be the users UID for the Person
  // domain and the users GID for the Group.  The meaning of id for
  // the domain Org or on non-POSIX systems is site defined.
  //
  // For a given domain/id pair the same token may be returned for up to
  // 7 minutes and 10 seconds.
  factory UUID.withDCESecurity(Domain domain, int id) {
    final uuid = UUID();

    uuid.bytes[6] = (uuid.bytes[6] & 0x0f) | 0x20; // Version 2
    uuid.bytes[9] = domain;

    // Write the id in big endian.
    // TODO: check if that is correct.
    uuid.bytes[3] = id;
    uuid.bytes[2] = (id >> 8);
    uuid.bytes[1] = (id >> 16);
    uuid.bytes[0] = (id >> 24);
    return uuid;
  }

  // NewDCEPerson returns a DCE Security (Version 2) UUID in the person
  // domain with the id returned by os.Getuid.
  //
  //  NewDCESecurity(Person, uint32(os.Getuid()))
  // TODO: need to find a way to get the user id.
  // factory UUID.withDCEPerson() {
  //   return UUID.withDCESecurity(person, uint32(os.Getuid()))
  // }

  // NewDCEGroup returns a DCE Security (Version 2) UUID in the group
  // domain with the id returned by os.Getgid.
  //
  //  NewDCESecurity(Group, uint32(os.Getgid()))
  // TODO: need to find a way to get the group id.
  // func NewDCEGroup() (UUID, error) {
  //   return NewDCESecurity(Group, uint32(os.Getgid()))
  // }

  // domain returns the domain for a Version 2 UUID.  Domains are only defined
  // for Version 2 UUIDs.
  Domain get domain => bytes[9];

  // id returns the id for a Version 2 UUID. IDs are only defined for Version 2
  // UUIDs.
  int get id => bytes[0] << 24 + bytes[1] << 16 + bytes[2] << 8 + bytes[3];
}

typedef Version = int;

extension VersionString on Version {
  String asString() {
    if (this > 15) {
      return 'BAD_VERSION_$this';
    }
    return 'VERSION_$this';
  }
}

// setRand sets the random number generator to r.
// If r.Read returns an error when the package requests random data then
// a panic will be issued.
//
// Calling setRand with nil sets the random number generator to the default
// generator.
void setRand(Random? r) {
  if (r == null) {
    rander = Random.secure();
    return;
  }
  rander = r;
}

// EnableRandPool enables internal randomness pool used for Random
// (Version 4) UUID generation. The pool contains random bytes read from
// the random number generator on demand in batches. Enabling the pool
// may improve the UUID generation throughput significantly.
//
// Since the pool is stored on the heap, this feature may be a bad fit
// for security sensitive applications.
void enableRandPool() {
  poolEnabled = true;
}

// disableRandPool disables the randomness pool if it was previously
// enabled with EnableRandPool.
void disableRandPool() {
  poolEnabled = false;
  poolPos = randPoolSize;
}
