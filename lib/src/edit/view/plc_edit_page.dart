import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app1/src/edit/bloc/plc_edit_bloc.dart';
import 'package:flutter_app1/src/list/list.dart';
import 'package:flutter_app1/src/repo/plc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlcEditPage extends StatelessWidget {
  static Route route(PlcItem data) {
    return MaterialPageRoute(
      builder: (context) => PlcEditPage(data: data),
    );
  }

  final PlcItem data;
  const PlcEditPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlcEditBloc(context.read<Plc>(), data),
      child: const PlcEditView(),
    );
  }
}

class PlcEditView extends StatelessWidget {
  const PlcEditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isValid = context
        .select((PlcEditBloc bloc) => bloc.state.status == PlcEditStatus.valid);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Value'),
        actions: [
          TextButton(
            onPressed: isValid
                ? () {
                    context.read<PlcEditBloc>().add(const PlcSummited());
                  }
                : null,
            child: const Text('Summit'),
          ),
        ],
      ),
      body: BlocBuilder<PlcEditBloc, PlcEditState>(
        builder: (context, state) {
          return Stack(
            children: [
              ListTile(
                leading: Text('DT${state.data?.address}'),
                title: TextFormField(
                  initialValue: '${state.value}',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    context.read<PlcEditBloc>().add(PlcValueChanged(value));
                  },
                ),
              ),
              if (state.status == PlcEditStatus.inProgress)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
