import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EpisodeView extends StatelessWidget {
  const EpisodeView({super.key});

  Widget buildBody(BuildContext context) {
    return Center(child: Text('episode'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () {
            context.go("/");
          },
        ),
      ),
      body: buildBody(context),
    );
  }
}
