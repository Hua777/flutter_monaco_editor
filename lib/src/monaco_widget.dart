library flutter_monaco_editor;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'dart:ui_web';

import 'package:flutter/cupertino.dart';
import 'package:flutter_monaco_editor/src/monaco_js.dart';
import 'package:uuid/uuid.dart';

class MonacoWidget extends StatefulWidget {
  final Map? options;
  final Function? beforeLoad;
  final Function? afterLoad;

  final String? value;
  final String? language;
  final bool? readOnly;
  final String? theme;

  const MonacoWidget({
    super.key,
    this.options,
    this.beforeLoad,
    this.afterLoad,
    this.value,
    this.language,
    this.readOnly,
    this.theme,
  });

  @override
  State<StatefulWidget> createState() {
    return MonacoWidgetState();
  }
}

class MonacoWidgetState extends State<MonacoWidget> {
  late MonacoJs monacoJs;

  final String _monacoId = '#${const Uuid().v4()}';
  late DivElement _monacoDiv;

  @override
  void initState() {
    super.initState();

    platformViewRegistry.registerViewFactory(_monacoId, (viewId) {
      _monacoDiv = DivElement();
      _monacoDiv.id = _monacoId;
      _monacoDiv.style.width = '100%';
      _monacoDiv.style.height = '100%';
      return _monacoDiv;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Map finalOptions = widget.options ?? {};
      if (widget.value != null) {
        finalOptions['value'] = widget.value;
      }
      if (widget.language != null) {
        finalOptions['language'] = widget.language;
      }
      if (widget.readOnly != null) {
        finalOptions['readOnly'] = widget.readOnly;
      }
      if (widget.theme != null) {
        finalOptions['theme'] = widget.theme;
      }
      if (widget.beforeLoad != null) {
        widget.beforeLoad!();
      }
      monacoJs = MonacoJs.fromElement(_monacoDiv, finalOptions);
      if (widget.afterLoad != null) {
        widget.afterLoad!();
      }
    });
  }

  @override
  void dispose() {
    monacoJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _monacoId,
    );
  }
}
