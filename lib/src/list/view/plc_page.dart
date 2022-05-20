import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app1/src/edit/view/plc_edit_page.dart';
import 'package:flutter_app1/src/list/bloc/plc_bloc.dart';
import 'package:flutter_app1/src/repo/plc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlcPage extends StatelessWidget {
  const PlcPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PlcBloc(context.read<Plc>())..add(const PlcConnected()),
      child: const PlcView(),
    );
  }
}

class PlcView extends StatelessWidget {
  const PlcView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plc Demo'),
      ),
      body: BlocBuilder<PlcBloc, PlcState>(
        builder: (context, state) {
          switch (state.status) {
            case PlcStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PlcStatus.success:
              return ListView.builder(
                itemCount: state.data.length,
                itemBuilder: (context, index) {
                  final item = state.data[index];
                  return ListTile(
                    leading: Text('DT${item.address}'),
                    title: Text('${item.value}'),
                    onTap: () {
                      Navigator.push(context, PlcEditPage.route(item));
                    },
                  );
                },
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
