import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'model.dart';

class ChannelView extends StatelessWidget {
  final int id;
  final ChannelViewModel model;
  ChannelView({super.key, required this.id, required this.model}) {
    model.load(id);
  }

  Widget buildBody(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(children: [Text(model.channel?.title ?? "")]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () {
            context.go("/subscribed");
          },
        ),
        title: Text("Channel Info"),
        actions: [
          TextButton.icon(
            label: Text('delete'),
            icon: Icon(Icons.delete_rounded),
            onPressed: () async {
              await model.delete();
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: buildBody(context),
    );
  }
}
