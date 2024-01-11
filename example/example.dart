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

  void beforeMonacoLoad() {}

  void oafterMonacoLoad() {
    // 插入文字
    monacoKey.currentState?.monacoJs.addAction(
      'diy-insert-text',
      '插入文字 (abcd)',
      (p0) {
        monacoKey.currentState?.monacoJs.setSelectionValue('abcd');
      },
      keybindings: [MonacoKeyMod.CtrlCmd.value | MonacoKeyMod.Alt.value | MonacoKeyCode.KeyL.value], // Ctrl + Alt + L
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,
    );

    // 设置文字
    monacoKey.currentState?.monacoJs.addAction(
      'diy-set-text',
      '覆盖文字 (hua777)',
      (p0) {
        monacoKey.currentState?.monacoJs.setValue('hua777');
      },
      keybindings: [MonacoKeyMod.CtrlCmd.value | MonacoKeyMod.Alt.value | MonacoKeyCode.KeyL.value], // Ctrl + Alt + L
      contextMenuGroupId: 'navigation',
      contextMenuOrder: 1.5,
    );

    // 内容变更事件
    monacoKey.currentState?.monacoJs.onDidChangeModelContent(() {
      print(monacoKey.currentState?.monacoJs.getSelectionValueOrValue());
    });
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
        language: 'clickhouse-sql',
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
