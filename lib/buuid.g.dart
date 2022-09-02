// GENERATED CODE - DO NOT MODIFY BY HAND

part of buuid;

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UUIDAdapter extends TypeAdapter<UUID> {
  @override
  final int typeId = 0;

  @override
  UUID read(BinaryReader reader) {
    return UUID();
  }

  @override
  void write(BinaryWriter writer, UUID obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.bytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UUIDAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
