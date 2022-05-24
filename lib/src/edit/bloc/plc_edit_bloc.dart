import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app1/src/list/model/plc_item.dart';
import 'package:flutter_app1/src/repo/plc.dart';

part 'plc_edit_event.dart';
part 'plc_edit_state.dart';

class PlcEditBloc extends Bloc<PlcEditEvent, PlcEditState> {
  final Plc _plc;
  PlcEditBloc(this._plc, PlcItem data)
      : super(PlcEditState(
          status: PlcEditStatus.valid,
          data: data,
          value: data.value,
        )) {
    on<PlcValueChanged>((event, emit) {
      final n = int.tryParse(event.value);
      if (n == null) {
        emit(state.copyWith(status: PlcEditStatus.invalid));
      } else {
        emit(state.copyWith(status: PlcEditStatus.valid, value: n));
      }
    });
    on<PlcSummited>((event, emit) async {
      final data = state.data;
      if (data == null) {
        emit(state.copyWith(status: PlcEditStatus.failure));
        return;
      }
      emit(state.copyWith(status: PlcEditStatus.inProgress));
      _plc.writeInt(data.address + 2, state.value);
      // _plc.writeInt(data.address + 5, state.value);
      final res = await _plc.writeInt(data.address, state.value);
      if (res == null) {
        emit(state.copyWith(status: PlcEditStatus.failure));
      } else {
        emit(state.copyWith(
          status: PlcEditStatus.submitted,
          data: PlcItem(address: data.address, value: res),
          value: res,
        ));
      }
    });
  }
}
