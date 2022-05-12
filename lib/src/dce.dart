part of buuid;

// A Domain represents a Version 2 domain
typedef Domain = int;

// Domain constants for DCE Security (Version 2) UUIDs.
const Domain person = 0;
const Domain group = 1;
const Domain org = 2;

extension DomainAsString on Domain {
  String asString() {
    switch (this) {
      case person:
        return 'Person';
      case group:
        return 'Group';
      case org:
        return 'Org';
    }
    return 'Domain$this';
  }
}
