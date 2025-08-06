import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'model.dart';

class CuratedView extends StatelessWidget {
  final CuratedViewModel model;
  const CuratedView({super.key, required this.model});

  Widget buildBody(BuildContext text) {
    return Center(child: Text('favorites'));
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
      ),
      body: buildBody(context),
    );
  }
}
