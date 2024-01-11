import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco_editor/flutter_monaco_editor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MonacoJs.load(); // 加载 Monaco
  runApp(const MainApp());
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PageState();
  }
}

class _PageState extends State<Page> {
  final GlobalKey<MonacoWidgetState> monacoKey = GlobalKey();

  void beforeMonacoLoad() {
    // 自定义代码完成
    MonacoJs.languagesRegisterCompletionItemProvider('mysql', (
      model,
      posisition,
      beforeWord,
      beforeWordRange,
      singleWord,
      singleWordRange,
    ) {
      return [
        {
          'label': "simpleText",
          'kind': MonacoLanguagesCompletionItemKind.Text.value,
          'insertText': "simpleText",
          'range': singleWordRange,
        }
      ];
    });
  }

  void oafterMonacoLoad() {
    // 自定义菜单
    monacoKey.currentState?.monacoJs.addAction(
      'diy-format',
      '格式化',
      (p0) {
        print('格式化');
      },
      keybindings: [2048 | 512 | 42], // Ctrl + Alt + L
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 500,
      child: MonacoWidget(
        key: monacoKey,
        language: 'mysql',
        theme: 'vs-dark',
        beforeLoad: beforeMonacoLoad,
        afterLoad: oafterMonacoLoad,
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  String? routeBeforeHook(RouteSettings settings) {
    return settings.name;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monaco Example',
      theme: ThemeData(
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        String? routeName = routeBeforeHook(settings);
        return CupertinoPageRoute(
          builder: (context) {
            switch (routeName) {
              case '/':
                return const Page();
              default:
                return Container();
            }
          },
        );
      },
    );
  }
}
