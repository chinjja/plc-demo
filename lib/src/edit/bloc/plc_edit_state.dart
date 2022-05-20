part of 'plc_edit_bloc.dart';

enum PlcEditStatus {
  invalid,
  valid,
  inProgress,
  submitted,
  failure,
}

class PlcEditState extends Equatable {
  final PlcEditStatus status;
  final PlcItem? data;
  final int value;

  const PlcEditState({
    this.status = PlcEditStatus.invalid,
    this.data,
    this.value = 0,
  });

  PlcEditState copyWith({
    PlcEditStatus? status,
    PlcItem? data,
    int? value,
  }) {
    return PlcEditState(
      status: status ?? this.status,
      data: data ?? this.data,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [status, data, value];
}
