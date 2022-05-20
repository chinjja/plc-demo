import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app1/src/list/model/plc_item.dart';
import 'package:flutter_app1/src/repo/plc.dart';

part 'plc_event.dart';
part 'plc_state.dart';

class PlcBloc extends Bloc<PlcEvent, PlcState> {
  final Plc _plc;
  PlcBloc(this._plc) : super(const PlcState()) {
    on<PlcConnected>((event, emit) async {
      emit(state.copyWith(status: PlcStatus.loading));
      _plc.register(const ReadCoils(address: 0, amount: 1760));
      _plc.register(const ReadInputs(address: 0, amount: 1760));
      _plc.register(const ReadHoldingRegisters(address: 0, amount: 125));
      await _plc.connect();
      await emit.forEach(_plc.onDataRegisters, onData: (Map<int, int> data) {
        final list = data.entries
            .map((e) => PlcItem(address: e.key, value: e.value))
            .toList();
        return state.copyWith(status: PlcStatus.success, data: list);
      });
    });
    on<PlcRequest>((event, emit) async {
      if (state.status != PlcStatus.success) return;
      await _plc.writeInt(event.address, event.value);
    });
  }

  @override
  Future<void> close() async {
    await _plc.close();
    return super.close();
  }
}
