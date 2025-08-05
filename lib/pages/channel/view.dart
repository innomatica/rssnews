import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'model.dart';

class ChannelView extends StatelessWidget {
  final ChannelViewModel model;
  const ChannelView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    return Center(child: Text('channel'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () {
            context.go("/subscriptions");
          },
        ),
      ),
      body: buildBody(context),
    );
  }
}
