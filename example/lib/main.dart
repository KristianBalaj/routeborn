import 'package:example/src/home_page.dart';
import 'package:example/src/page_404.dart';
import 'package:example/src/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:routeborn/routeborn.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

NavigationStack<NestingBranch> initialPages() => NavigationStack(
      [AppPageNode(page: HomePage())],
    );

final navigationNotifierProvider =
    ChangeNotifierProvider((_) => NavigationNotifier(routes));

final rootRouterDelegate = Provider((ref) =>
    RoutebornRootRouterDelegate(ref.watch(navigationNotifierProvider)));

class MyApp extends HookWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerDelegate: useProvider(rootRouterDelegate),
      routeInformationParser: RoutebornRouteInfoParser(
        page404: Page404(),
        initialStackBuilder: initialPages,
        routes: routes,
      ),
    );
  }
}
