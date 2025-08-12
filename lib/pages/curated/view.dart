import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/constant.dart';
import 'model.dart';

class CuratedView extends StatelessWidget {
  final CuratedViewModel model;
  const CuratedView({super.key, required this.model});

  Widget buildBody(BuildContext context) {
    final categoryColor = Theme.of(context).colorScheme.primary;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        return ListView.builder(
          itemCount: model.curated.length,
          itemBuilder: (context, index) {
            final info = model.curated[index];
            return ExpansionTile(
              title: Text(
                info.category,
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: info.items.map((e) {
                return ListTile(
                  leading: Image.network(
                    e.favicon,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) {
                      return Image.asset(
                        assImageRssIcon,
                        width: 26,
                        height: 26,
                      );
                    },
                  ),
                  title: Text(e.title),
                  onTap: () {
                    context.push(
                      Uri(
                        path: '/browser',
                        queryParameters: {"url": e.feedUrl},
                      ).toString(),
                    );
                  },
                );
              }).toList(),
            );
          },
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
      ),
      body: buildBody(context),
    );
  }
}
