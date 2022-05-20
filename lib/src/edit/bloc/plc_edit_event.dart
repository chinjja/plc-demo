part of 'plc_edit_bloc.dart';

abstract class PlcEditEvent extends Equatable {
  const PlcEditEvent();

  @override
  List<Object> get props => [];
}

class PlcValueChanged extends PlcEditEvent {
  final String value;
  const PlcValueChanged(this.value);

  @override
  List<Object> get props => [value];
}

class PlcSummited extends PlcEditEvent {
  const PlcSummited();
}
