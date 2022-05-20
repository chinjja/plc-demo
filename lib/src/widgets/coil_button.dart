import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app1/src/repo/plc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoilButton extends StatefulWidget {
  final int address;
  final VoidCallback? onPressed;
  final Widget? child;
  const CoilButton({
    Key? key,
    required this.address,
    this.onPressed,
    this.child,
  }) : super(key: key);

  @override
  State<CoilButton> createState() => _CoilButtonState();
}

class _CoilButtonState extends State<CoilButton> {
  late final Stream<bool> _stream;
  bool state = false;

  @override
  void initState() {
    super.initState();
    _stream = context
        .read<Plc>()
        .onCoils
        .map((event) => event[widget.address] ?? false)
        .distinct((a, b) => a == b);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? false;
        print(state);
        return Material(
          color: state ? Colors.orange : Colors.grey,
          child:
              InkWell(onTap: widget.onPressed ?? _toggle, child: widget.child),
        );
      },
    );
  }

  void _toggle() {
    // context
    //     .read<Plc>().write(address, value)
  }
}
