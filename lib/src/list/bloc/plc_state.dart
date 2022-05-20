part of 'plc_bloc.dart';

enum PlcStatus {
  initial,
  loading,
  success,
  failure,
}

class PlcState extends Equatable {
  final PlcStatus status;
  final List<PlcItem> data;

  const PlcState({this.status = PlcStatus.initial, this.data = const []});

  PlcState copyWith({PlcStatus? status, List<PlcItem>? data}) {
    return PlcState(status: status ?? this.status, data: data ?? this.data);
  }

  @override
  List<Object> get props => [status, data];
}
