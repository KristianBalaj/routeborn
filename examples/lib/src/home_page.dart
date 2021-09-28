import 'package:dartz/dartz.dart';
import 'package:examples/main.dart';
import 'package:examples/src/help_page.dart';
import 'package:examples/src/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:routeborn/routeborn.dart';

class HomePage extends RoutebornPage {
  static const pagePathBase = 'home';

  HomePage() : super.builder(pagePathBase, (_) => const HomePageView());

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      const Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}

final nestedRouterDelegate = Provider.family(
  (ref, branch) => RoutebornNestedRouterDelegate(
      ref.watch(navigationNotifierProvider),
      branch: branch),
);

class HomePageView extends HookWidget {
  const HomePageView({Key? key}) : super(key: key);

  NestingBranch index2Branch(int index) {
    switch (index) {
      case 0:
        return NestingBranch.shop;
      case 1:
        return NestingBranch.favorites;
    }
    throw FlutterError('Cannot have other branch');
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = useProvider(
      navigationNotifierProvider.select(
        (value) {
          switch (value.getNestingBranch(context, inChildNavigator: true)) {
            case NestingBranch.shop:
              return 0;
            case NestingBranch.favorites:
              return 1;
          }
        },
      ),
    );

    final ctrl =
        useMemoized(() => CupertinoTabController(initialIndex: currentTab));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              context
                  .read(navigationNotifierProvider)
                  .pushPage(context, AppPageNode(page: HelpPage()));
            },
            icon: Icon(Icons.help),
          ),
        ],
      ),
      body: SafeArea(
        child: CupertinoTabScaffold(
          controller: ctrl,
          tabBar: CupertinoTabBar(
            onTap: (tabId) {
              // `setNestingBranch` here is called with the parameter `inChildNavigator: true`
              // Because the Router is in the same context.

              // Other possible solution in this case would be to wrap
              // `BottomNavigationBar` with `Builder()` widget. After that,
              // the parameter `inChildNavigator: true` would not be needed
              context.read(navigationNotifierProvider).setNestingBranch(
                    context,
                    index2Branch(tabId),
                    inChildNavigator: true,
                  );
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_basket), label: 'Shop'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite), label: 'Favorites'),
            ],
          ),
          tabBuilder: (BuildContext context, int index) =>
              _Tab(index2Branch(index)),
        ),
      ),
    );
  }
}

class _Tab extends HookWidget {
  final NestingBranch branch;

  const _Tab(this.branch, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Router(routerDelegate: useProvider(nestedRouterDelegate(branch)));
  }
}
