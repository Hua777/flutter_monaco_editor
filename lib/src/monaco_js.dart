// ignore_for_file: constant_identifier_names

library flutter_monaco_editor;

// ignore: avoid_web_libraries_in_flutter
import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/foundation.dart';

enum MonacoLanguagesCompletionItemKind {
  Method(0),
  Function(1),
  Constructor(2),
  Field(3),
  Variable(4),
  Class(5),
  Struct(6),
  Interface(7),
  Module(8),
  Property(9),
  Event(10),
  Operator(11),
  Unit(12),
  Value(13),
  Constant(14),
  Enum(15),
  EnumMember(16),
  Keyword(17),
  Text(18),
  Color(19),
  File(20),
  Reference(21),
  Customcolor(22),
  Folder(23),
  TypeParameter(24),
  User(25),
  Issue(26),
  Snippet(27),
  ;

  final int value;

  const MonacoLanguagesCompletionItemKind(this.value);
}

enum MonacoLanguagesCompletionItemInsertTextRule {
  None(0),
  KeepWhitespace(1),
  InsertAsSnippet(4),
  ;

  final int value;

  const MonacoLanguagesCompletionItemInsertTextRule(this.value);
}

class MonacoJs {
  static final Map<JsObject?, MonacoJs> _instances = {};

  JsObject? _editorJs;

  static JsObject? get _require => context['require'];
  static JsObject? get _monaco => context['monaco'];
  static JsObject? get _monacoEditor => _monaco?['editor'];
  static JsObject? get _monacoLanguages => _monaco?['languages'];
  static JsFunction? get _monacoEditorCreate => _monacoEditor?['create'];
  static JsFunction? get _monacoLanguagesRegister => _monacoLanguages?['register'];
  static JsFunction? get _monacoLanguagesSetMonarchTokensProvider => _monacoLanguages?['setMonarchTokensProvider'];
  static JsFunction? get _monacoLanguagesRegisterCompletionItemProvider => _monacoLanguages?['registerCompletionItemProvider'];

  static Future<void> _waitForGetting() async {
    if (_monaco == null) {
      if (kDebugMode) {
        print('[monaco] getting...');
      }
      return Future.delayed(
        const Duration(seconds: 1),
        () {
          return _waitForGetting();
        },
      );
    }
  }

  static Future<void> load() async {
    if (kDebugMode) {
      print('[monaco] preparing');
    }
    final NodeValidatorBuilder htmlValidator = NodeValidatorBuilder.common()
      ..allowElement('link', attributes: ['rel', 'href', 'data-name'])
      ..allowElement('script', attributes: ['src']);
    (document.getElementsByTagName('body')[0] as HtmlElement).insertAdjacentHtml(
      'afterBegin',
      '''
<link rel="stylesheet" data-name="vs/editor/editor.main" href="/vs/editor/editor.main.css">
<script>require.config({ paths: { 'vs': '/vs' }});</script>
<script src="/vs/loader.js"></script>
<script src="/vs/editor/editor.main.nls.js"></script>
<script src="/vs/editor/editor.main.js"></script>
  ''',
      validator: htmlValidator,
    );
    if (_require == null) {
      throw Exception('未能正确加载 Reuire');
    }
    if (kDebugMode) {
      print('[monaco] loading');
    }
    await _waitForGetting();
    if (kDebugMode) {
      print('[monaco] loaded');
    }
  }

  ///
  /// 注册新的语言
  ///
  static void languagesRegister(String id, {Map? options}) {
    options ??= {};
    options['id'] = id;
    _monacoLanguagesRegister?.apply([JsObject.jsify(options)]);
  }

  ///
  /// 对新的语言配置 Monarch
  ///
  static void languagesSetMonarchTokensProvider(String id, Map options) {
    _monacoLanguagesSetMonarchTokensProvider?.apply([id, JsObject.jsify(options)]);
  }

  ///
  /// 对新的语言配置自动完成
  ///
  static void languagesRegisterCompletionItemProvider(
    String id,
    List<Map> Function(
      JsObject model,
      JsObject position,
      String beforeWord,
      Map beforeWordRange,
      String singleWord,
      Map singleWordRange,
    ) provideCompletionItems, {
    Map? options,
  }) {
    options ??= {};
    options['provideCompletionItems'] = (JsObject model, JsObject position) {
      var beforeWordRange = {
        'startLineNumber': position['lineNumber'],
        'endLineNumber': position['lineNumber'],
        'startColumn': 0,
        'endColumn': position['column'],
      };
      var beforeWord = model.callMethod('getValueInRange', [JsObject.jsify(beforeWordRange)]);
      var singleWord = model.callMethod('getWordUntilPosition', [position]);
      var singleWordRange = {
        'startLineNumber': position['lineNumber'],
        'endLineNumber': position['lineNumber'],
        'startColumn': singleWord['startColumn'],
        'endColumn': singleWord['endColumn'],
      };
      return JsObject.jsify({
        'suggestions': provideCompletionItems(
          model,
          position,
          beforeWord,
          beforeWordRange,
          singleWord['word'],
          singleWordRange,
        )
      });
    };
    _monacoLanguagesRegisterCompletionItemProvider?.apply([id, JsObject.jsify(options)]);
  }

  ///
  /// 创建
  ///
  MonacoJs.fromElement(Element element, Map options) {
    _editorJs = _monacoEditorCreate?.apply([element, JsObject.jsify(options)]);
    if (_editorJs != null) {
      _instances[_editorJs] = this;
    }
  }

  ///
  /// 给右键菜单加自己想要的菜单
  ///
  void addAction(
    String id,
    String label,
    Function(MonacoJs) run, {
    required String contextMenuGroupId,
    required num contextMenuOrder,
    Map? options,
    String? precondition,
    String? keybindingContext,
    List<num>? keybindings,
  }) {
    options ??= {};
    options['id'] = id;
    options['label'] = label;
    options['run'] = (editor) {
      run(_instances[editor]!);
    };
    options['contextMenuGroupId'] = contextMenuGroupId;
    options['contextMenuOrder'] = contextMenuOrder;
    if (precondition != null) {
      options['precondition'] = precondition;
    }
    if (keybindingContext != null) {
      options['keybindingContext'] = keybindingContext;
    }
    if (keybindings != null) {
      options['keybindings'] = keybindings;
    }
    _editorJs?.callMethod('addAction', [JsObject.jsify(options)]);
  }
}
