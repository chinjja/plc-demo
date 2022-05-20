import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:modbus/modbus.dart' as modbus;
import 'package:rxdart/rxdart.dart';

class Plc {
  int get maxDataLength => 125;
  int get maxBitLength => 1760;

  final String ip;
  modbus.ModbusClient? client;

  Plc(this.ip);

  final _coils = BehaviorSubject.seeded(<int, bool>{});
  final _inputs = BehaviorSubject.seeded(<int, bool>{});
  final _dataRegisters = BehaviorSubject.seeded(<int, int>{});
  final _inputRegisters = BehaviorSubject.seeded(<int, int>{});
  final _queue = Queue<ReadRequest>();
  late final _repeat = RepeatStream<_Request>((_) async* {
    if (_queue.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
    } else {
      final item = _queue.removeFirst();
      _queue.add(item);
      yield item;
    }
  });
  final _trigger = BehaviorSubject();
  late final _triggerStream =
      _trigger.sampleTime(const Duration(milliseconds: 100));
  final _write = BehaviorSubject<WriteValue>();
  late final _writeGather = _write.stream
      .buffer(_triggerStream)
      .where((e) => e.isNotEmpty)
      .flatMap((list) async* {
    list = list.toList();
    list.sort((a, b) => a.address.compareTo(b.address));
    final prev = await _dataRegisters.first;
    final data = <int>[];
    final obj = <WriteValue>[];
    var startAddress = list.first.address;

    send() async* {
      final req = WriteMultiRegisters(
        address: startAddress,
        data: Uint16List.fromList(data),
      );
      yield req;
      try {
        await req.future;
        for (final o in obj) {
          o._completer.complete();
        }
      } catch (e) {
        for (var o in obj) {
          o._completer.completeError(e);
        }
      }
    }

    for (int i = 0; i < list.length; i++) {
      final s = list[i];
      data.add(s.data);
      obj.add(s);
      if (i == list.length - 1) {
        yield* send();
        break;
      }
      final e = list[i + 1];
      if (s.address == e.address) {
        data.removeLast();
      }

      if (e.address - startAddress >= maxDataLength) {
        yield* send();
        startAddress = e.address;
        data.clear();
        obj.clear();
        continue;
      }
      for (int j = s.address + 1; j < e.address; j++) {
        data.add(prev[j] ?? 0);
      }
    }
  });
  final _writeCoils = BehaviorSubject<WriteBit>();
  late final _writeCoilsGather = _writeCoils.stream
      .buffer(_triggerStream)
      .where((e) => e.isNotEmpty)
      .flatMap((list) async* {
    list = list.toList();
    list.sort((a, b) => a.address.compareTo(b.address));
    final prev = await _coils.first;
    final data = <bool>[];
    final obj = <WriteBit>[];
    var startAddress = list.first.address;

    send() async* {
      final req = WriteMultiCoils(
        address: startAddress,
        data: [...data],
      );
      yield req;
      try {
        await req.future;
        for (final o in obj) {
          o._completer.complete();
        }
      } catch (e) {
        for (var o in obj) {
          o._completer.completeError(e);
        }
      }
    }

    for (int i = 0; i < list.length; i++) {
      final s = list[i];
      data.add(s.data);
      obj.add(s);
      if (i == list.length - 1) {
        yield* send();
        break;
      }
      final e = list[i + 1];
      if (s.address == e.address) {
        data.removeLast();
      }

      if (e.address - startAddress >= maxDataLength) {
        yield* send();
        startAddress = e.address;
        data.clear();
        obj.clear();
        continue;
      }
      for (int j = s.address + 1; j < e.address; j++) {
        data.add(prev[j] ?? false);
      }
    }
  });

  StreamSubscription? _subscription;
  Stream<Map<int, bool>> get onCoils => _coils.stream;
  Stream<Map<int, bool>> get onInputs => _inputs.stream;
  Stream<Map<int, int>> get onDataRegisters => _dataRegisters.stream;
  Stream<Map<int, int>> get onInputRegisters => _inputRegisters.stream;

  Future<void> connect() async {
    if (client != null) return;
    client = modbus.createTcpClient(ip);

    await client!.connect();

    _subscription = Rx.merge<_Request>([
      _repeat,
      _writeGather,
      _writeCoilsGather,
    ]).asyncMap((event) async {
      if (event is WriteSingleRegister) {
        final res = await client!.writeSingleRegister(
          event.address,
          event.data,
        );

        final data = _updateSingle(
          await _dataRegisters.first,
          event.address,
          res,
        );
        _dataRegisters.add(data);

        event._completer.complete(res);
      } else if (event is WriteSingleCoil) {
        final res = await client!.writeSingleCoil(
          event.address,
          event.data,
        );

        final data = _updateSingle(
          await _coils.first,
          event.address,
          res,
        );
        _coils.add(data);

        event._completer.complete(res);
      } else if (event is WriteMultiRegisters) {
        await client!.writeMultipleRegisters(
          event.address,
          event.data,
        );

        final data = _update(
          await _dataRegisters.first,
          event.address,
          event.data,
        );
        _dataRegisters.add(data);
        event._completer.complete();
      } else if (event is WriteMultiCoils) {
        await client!.writeMultipleCoils(
          event.address,
          event.data,
        );

        final data = _update(
          await _coils.first,
          event.address,
          event.data,
        );
        _coils.add(data);
        event._completer.complete();
      } else if (event is ReadHoldingRegisters) {
        final res = await client!.readHoldingRegisters(
          event.address,
          event.amount,
        );

        final data = _update(await _inputRegisters.first, event.address, res);
        _dataRegisters.add(data);
      } else if (event is ReadInputRegisters) {
        final res = await client!.readInputRegisters(
          event.address,
          event.amount,
        );

        final data = _update(await _inputRegisters.first, event.address, res);
        _inputRegisters.add(data);
      } else if (event is ReadCoils) {
        final res = await client!.readCoils(
          event.address,
          event.amount,
        );

        final data = _update(await _coils.first, event.address, res)
            .map((key, value) => MapEntry(key, value ?? false));
        _coils.add(data);
      } else if (event is ReadInputs) {
        final res = await client!.readDiscreteInputs(
          event.address,
          event.amount,
        );

        final data = _update(await _inputs.first, event.address, res)
            .map((key, value) => MapEntry(key, value ?? false));
        _inputs.add(data);
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }).listen(null);
  }

  Future<void> close() async {
    if (client == null) return;
    await _subscription?.cancel();
    await client?.close();
    client = null;
  }

  bool isOpen() {
    return client != null;
  }

  Map<int, T> _update<T>(Map<int, T> map, int address, List<T> data) {
    final copy = Map<int, T>.from(map);
    for (int i = 0; i < data.length; i++) {
      copy[i + address] = data[i];
    }
    return copy;
  }

  Map<int, T> _updateSingle<T>(Map<int, T> map, int address, T data) {
    final copy = Map<int, T>.from(map);
    copy[address] = data;
    return copy;
  }

  Future<int?> writeInt(int address, int value) async {
    final request = WriteValue(
      address: address,
      data: value,
    );
    _write.add(request);
    _trigger.add(request);
    await request.future;
    return value;
  }

  Future<bool?> writeCoil(int address, bool value) async {
    final request = WriteBit(
      address: address,
      data: value,
    );
    _writeCoils.add(request);
    _trigger.add(request);
    await request.future;
    return value;
  }

  void register(ReadRequest data) {
    _queue.add(data);
  }

  void unregister(ReadRequest data) {
    _queue.remove(data);
  }
}

class WriteValue {
  final _completer = Completer<void>();
  Future<void> get future => _completer.future;
  final int address;
  final int data;
  WriteValue({required this.address, required this.data});
}

class WriteBit {
  final _completer = Completer<void>();
  Future<void> get future => _completer.future;
  final int address;
  final bool data;
  WriteBit({required this.address, required this.data});
}

abstract class _Request<T> {
  final int address;
  const _Request({required this.address});
}

abstract class ReadRequest<T> extends _Request<T> {
  final int amount;
  const ReadRequest({required super.address, required this.amount});
}

abstract class WriteRequest<T> extends _Request<T> {
  final Completer<T> _completer = Completer();
  Future<T?> get future => _completer.future;
  WriteRequest({required super.address});
}

class ReadCoils extends ReadRequest<List<bool?>> {
  const ReadCoils({
    required super.address,
    required super.amount,
  });
}

class ReadInputs extends ReadRequest<List<bool?>> {
  const ReadInputs({
    required super.address,
    required super.amount,
  });
}

class ReadHoldingRegisters extends ReadRequest<Uint16List> {
  const ReadHoldingRegisters({
    required super.address,
    required super.amount,
  });
}

class ReadInputRegisters extends ReadRequest<Uint16List> {
  const ReadInputRegisters({
    required super.address,
    required super.amount,
  });
}

class WriteSingleRegister extends WriteRequest<int> {
  final int data;
  WriteSingleRegister({
    required super.address,
    required this.data,
  });
}

class WriteSingleCoil extends WriteRequest<bool> {
  final bool data;
  WriteSingleCoil({
    required super.address,
    required this.data,
  });
}

class WriteMultiRegisters extends WriteRequest<void> {
  final Uint16List data;
  WriteMultiRegisters({
    required super.address,
    required this.data,
  });
}

class WriteMultiCoils extends WriteRequest<void> {
  final List<bool> data;
  WriteMultiCoils({
    required super.address,
    required this.data,
  });
}
