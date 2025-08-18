import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/constants.dart';
import 'model.dart';

class ChannelView extends StatefulWidget {
  final ChannelViewModel model;
  const ChannelView({super.key, required this.model});

  @override
  State<ChannelView> createState() => _ChannelViewState();
}

class _ChannelViewState extends State<ChannelView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleControler = TextEditingController();
  final _linkController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  dispose() {
    _titleController.dispose();
    _subtitleControler.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void showLabelManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Label Editor'),
          content: Column(
            children: widget.model.labels
                .map(
                  (e) => TextFormField(
                    initialValue: e.title,
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.label_outline_rounded,
                        color: labelColor[e.color],
                      ),
                    ),
                    onChanged: (value) {
                      e.title = value;
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    ).then((value) {
      widget.model.updateLabels();
    });
  }

  Widget buildBody(BuildContext context) {
    // print('build:${widget.model.channel?.title}');
    _titleController.text = widget.model.channel?.title ?? "";
    _subtitleControler.text = widget.model.channel?.subtitle ?? "";
    _linkController.text = widget.model.channel?.link ?? "";
    _imageUrlController.text = widget.model.channel?.imageUrl ?? "";
    final titleStyle = TextStyle(fontSize: 12.0);
    final subtitleStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    );
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // title
          ListTile(
            title: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "title"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter title";
                }
                return null;
              },
            ),
          ),
          // subtitle
          ListTile(
            title: TextFormField(
              controller: _subtitleControler,
              decoration: InputDecoration(labelText: "subtitle"),
              validator: (value) {
                return null;
              },
            ),
          ),
          // link
          ListTile(
            title: TextFormField(
              controller: _linkController,
              decoration: InputDecoration(labelText: "link"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter link";
                } else if (!value.contains(".")) {
                  return "Please enter valid url";
                }
                return null;
              },
            ),
          ),
          // image url
          ListTile(
            title: TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(labelText: "image url"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter favicon url";
                } else if (!value.contains(".")) {
                  return "Please enter valid url";
                }
                return null;
              },
            ),
          ),
          // labels
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                ...widget.model.labels.map((e) {
                  // print('view.channel:${widget.model.channel}, ${e.id}');
                  final selected =
                      widget.model.channel?.labels?.contains(e.id) ?? false;
                  return FilterChip(
                    label: Text(
                      e.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? null : labelColor[e.color],
                      ),
                    ),
                    selected: selected,
                    selectedColor: labelColor[e.color],
                    onSelected: (value) {
                      widget.model.toggleLabel(e.id);
                    },
                  );
                }),
                IconButton(
                  icon: Icon(Icons.settings_outlined, size: 24.0),
                  onPressed: () => showLabelManager(context),
                ),
              ],
            ),
          ),
          // description
          ListTile(
            title: Text('description', style: titleStyle),
            subtitle: Text(
              widget.model.channel?.description ?? "",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ),
          // last checked
          ListTile(
            title: Text('last checked', style: titleStyle),
            subtitle: Text(
              widget.model.channel?.checked?.toIso8601String() ?? "",
              style: subtitleStyle,
            ),
          ),
          // last updated
          ListTile(
            title: Text('last updated', style: titleStyle),
            subtitle: Text(
              widget.model.channel?.updated?.toIso8601String() ?? "",
              style: subtitleStyle,
            ),
          ),
          // published
          ListTile(
            title: Text('published', style: titleStyle),
            subtitle: Text(
              widget.model.channel?.updated?.toIso8601String() ?? "",
              style: subtitleStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await widget.model.update({
                "title": _titleController.text,
                "subtitle": _subtitleControler.text,
                "link": _linkController.text,
                "imageUrl": _imageUrlController.text,
              });
              if (context.mounted) context.go("/subscribed");
            }
          },
        ),
        title: Text("Feed Channel"),
        actions: [
          TextButton.icon(
            label: Text('unsubscribe'),
            icon: Icon(Icons.unsubscribe_rounded),
            onPressed: () async {
              await widget.model.unsubcribe();
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) {
          return buildBody(context);
        },
      ),
    );
  }
}
