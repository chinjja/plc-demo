part of 'plc_bloc.dart';

abstract class PlcEvent extends Equatable {
  const PlcEvent();

  @override
  List<Object> get props => [];
}

class PlcConnected extends PlcEvent {
  const PlcConnected();
}

class PlcRequest extends PlcEvent {
  final int address;
  final int value;
  const PlcRequest({required this.address, required this.value});

  @override
  List<Object> get props => [address, value];
}
