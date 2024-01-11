library flutter_monaco_editor;

// ignore: avoid_web_libraries_in_flutter
import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

class MonacoJs {
  static final Map<JsObject?, MonacoJs> _instances = {};

  JsObject? _editorJs;

  static JsObject? get _require => context['require'];
  static JsObject? get _monaco => context['monaco'];
  static JsObject? get _monacoEditor => _monaco?['editor'];
  static JsObject? get _monacoLanguages => _monaco?['languages'];
  static JsFunction? get _monacoEditorCreate => _monacoEditor?['create'];
  static JsFunction? get _monacoLanguagesRegister => _monacoLanguages?['register'];
  static JsFunction? get _monacoLanguagesSetLanguageConfiguration => _monacoLanguages?['setLanguageConfiguration'];
  static JsFunction? get _monacoLanguagesSetMonarchTokensProvider => _monacoLanguages?['setMonarchTokensProvider'];
  static JsFunction? get _monacoLanguagesRegisterCompletionItemProvider => _monacoLanguages?['registerCompletionItemProvider'];

  static Future<void> _waitForGetting() async {
    if (_monaco == null) {
      print('[monaco] getting...');
      return Future.delayed(
        const Duration(seconds: 1),
        () {
          return _waitForGetting();
        },
      );
    }
  }

  static Future<void> load() async {
    print('[monaco] preparing');
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
    print('[monaco] loading');
    await _waitForGetting();
    print('[monaco] loaded');
  }

  ///
  /// Register information about a new language.
  ///
  static void languagesRegister(String id, {Map? options}) {
    options ??= {};
    options['id'] = id;
    _monacoLanguagesRegister?.apply([JsObject.jsify(options)]);
  }

  ///
  /// Set the editing configuration for a language.
  ///
  static void languagesSetLanguageConfiguration(String id, Map options) {
    _monacoLanguagesSetLanguageConfiguration?.apply([id, JsObject.jsify(options)]);
  }

  ///
  /// Set the tokens provider for a language (monarch implementation).
  /// This tokenizer will be exclusive with a tokenizer set using setTokensProvider,
  /// or with registerTokensProviderFactory,
  /// but will work together with a tokens provider set using registerDocumentSemanticTokensProvider or registerDocumentRangeSemanticTokensProvider.
  ///
  static void languagesSetMonarchTokensProvider(String id, Map options) {
    _monacoLanguagesSetMonarchTokensProvider?.apply([id, JsObject.jsify(options)]);
  }

  ///
  /// Register a completion item provider (use by e.g. suggestions).
  ///
  static void languagesRegisterCompletionItemProvider(
    String id,
    List<Map> Function(
      JsObject model,
      JsObject position,
    ) provideCompletionItems, {
    List<String>? triggerCharacters,
    Map? options,
  }) {
    options ??= {};
    if (triggerCharacters != null) {
      options['provideCompletionItems'] = triggerCharacters;
    }
    options['provideCompletionItems'] = (JsObject model, JsObject position) {
      return JsObject.jsify({
        'suggestions': provideCompletionItems(
          model,
          position,
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

  ///
  /// 内容变更事件
  ///
  void onDidChangeModelContent(Function function) {
    _editorJs?.callMethod('onDidChangeModelContent', [
      allowInterop((e) {
        function();
      })
    ]);
  }

  ///
  /// Type the getModel() of IEditor.
  ///
  JsObject? getModel() {
    return _editorJs?.callMethod('getModel');
  }

  ///
  /// Returns the primary selection of the editor.
  ///
  JsObject? getSelection() {
    return _editorJs?.callMethod('getSelection');
  }

  ///
  /// Get a range covering the entire model.
  ///
  JsObject? getFullModelRange() {
    return getModel()?.callMethod('getFullModelRange');
  }

  static (num, num, num, num) convertJsRangeToDart(JsObject? range) {
    var startLineNumber = range?['startLineNumber'];
    var startColumn = range?['startColumn'];
    var endLineNumber = range?['endLineNumber'];
    var endColumn = range?['endColumn'];
    return (startLineNumber, startColumn, endLineNumber, endColumn);
  }

  ///
  /// 现在是否选取着
  ///
  bool isSelected() {
    var (a, b, c, d) = convertJsRangeToDart(getSelection());
    return a != c || b != d;
  }

  ///
  /// 获取选择的文字，或是全部文字
  ///
  String getSelectionValueOrValue() {
    if (isSelected()) {
      return getModel()?.callMethod('getValueInRange', [getSelection()]);
    } else {
      return getModel()?.callMethod('getValue');
    }
  }

  ///
  /// 设置全部文字
  ///
  void setValue(String value) {
    var (a, b, c, d) = convertJsRangeToDart(getFullModelRange());
    _editorJs?.callMethod(
      'executeEdits',
      [
        'setSelectionValue',
        JsObject.jsify([
          {
            'range': {
              'startLineNumber': a,
              'startColumn': b,
              'endLineNumber': c,
              'endColumn': d,
            },
            'text': value
          },
        ]),
      ],
    );
  }

  ///
  /// 设置选中的文字
  ///
  void setSelectionValue(String value) {
    var (a, b, c, d) = convertJsRangeToDart(getSelection());
    _editorJs?.callMethod(
      'executeEdits',
      [
        'setSelectionValue',
        JsObject.jsify([
          {
            'range': {
              'startLineNumber': a,
              'startColumn': b,
              'endLineNumber': c,
              'endColumn': d,
            },
            'text': value
          },
        ]),
      ],
    );
  }

  ///
  /// 销毁
  ///
  void dispose() {
    _instances.remove(_editorJs);
    _editorJs?.callMethod('dispose');
  }
}
