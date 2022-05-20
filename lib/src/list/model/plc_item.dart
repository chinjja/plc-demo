import 'package:equatable/equatable.dart';

class PlcItem extends Equatable {
  final int address;
  final int value;

  const PlcItem({
    required this.address,
    required this.value,
  });

  @override
  List<Object?> get props => [address, value];
}
