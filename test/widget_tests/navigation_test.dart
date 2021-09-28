import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/routeborn_page.dart';
import 'package:routeborn/src/routeborn_route_info_parser.dart';
import 'package:routeborn/src/router_delegates/routeborn_nested_router_delegate.dart';
import 'package:routeborn/src/router_delegates/routeborn_root_router_delegate.dart';

import '../matchers/app_pages_matcher.dart';

final navigationProvider = Provider<NavigationNotifier<_TestNestingBranch>>(
    (_) => throw UnimplementedError());

enum _TestNestingBranch {
  shop,
  favorites,
  cart,
  categories,
}

void main() {
  final routes = <String, RouteNode<_TestNestingBranch>>{
    APage.pageKey: RouteNode(
      Right(() => APage()),
      routes: {
        BPage.pageKey: RouteNode(
          Right(() => BPage()),
          routes: {
            CPage.pageKey: RouteNode(Right(() => CPage())),
          },
        ),
      },
    ),
    DPage.pageKey: RouteNode(
      Right(() => DPage()),
      nestedBranches: NestedBranches(
        defaultBranch: _TestNestingBranch.shop,
        branches: {
          _TestNestingBranch.shop: BranchInitNode(
            EPage.pageKey,
            RouteNode(
              Right(() => EPage()),
              nestedBranches: NestedBranches(
                defaultBranch: _TestNestingBranch.categories,
                branches: {
                  _TestNestingBranch.categories: BranchInitNode(
                    FPage.pageKey,
                    RouteNode(Right(() => FPage())),
                  )
                },
              ),
              routes: {
                GPage.pageKey: RouteNode(
                  Right(() => GPage()),
                ),
                JPage.pageKey: RouteNode(
                  Right(() => JPage()),
                ),
              },
            ),
          ),
          _TestNestingBranch.favorites: BranchInitNode(
            HPage.pageKey,
            RouteNode(
              Right(() => HPage()),
            ),
          ),
          _TestNestingBranch.cart: BranchInitNode(
            IPage.pageKey,
            RouteNode(
              Right(() => IPage()),
              routes: {
                APage.pageKey: RouteNode(Right(() => APage())),
              },
            ),
          ),
        },
      ),
    ),
    KPage.pageKey: RouteNode(
      Right(() => KPage()),
      nestedBranches: NestedBranches(
        defaultBranch: _TestNestingBranch.shop,
        branches: {
          _TestNestingBranch.shop: BranchInitNode(
            LPage.pageKey,
            RouteNode(
              Right(() => LPage()),
              routes: {
                NPage.pageKey: RouteNode(Right(() => NPage())),
                OPage.pageKey: RouteNode(Right(() => OPage()))
              },
            ),
          ),
          _TestNestingBranch.favorites:
              BranchInitNode(MPage.pageKey, RouteNode(Right(() => MPage())))
        },
      ),
    ),
  };

  group('stack API operations', () {
    group('pushPage', () {
      testWidgets(
        'pushPage test without nesting',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: APage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton, BPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(APage, null),
              TestNode(BPage, null),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton, CPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(APage, null),
              TestNode(BPage, null),
              TestNode(CPage, null),
            ]),
          );
        },
      );

      testWidgets(
        'pushPage pushes page in nested level',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: DPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          /// From EPage
          await tester.tap(find.widgetWithText(TextButton, GPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets('pushPage to parent level', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: DPage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
            find.widgetWithText(TextButton, 'push parent ${GPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                    TestNode(GPage, null)
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      });

      testWidgets(
        'pushPage in nested level when the branches '
        'use separate navigator keys',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: KPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(
              TextButton, 'pushPage NPage from ${LPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(LPage, null),
                      TestNode(NPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'call pushPage before the initial router',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                builder: (context, router) {
                  return Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          navNotifier.pushPage(
                              context, AppPageNode(page: BPage()));
                        },
                        child: Text('push BPage'),
                      ),
                      Expanded(child: router!)
                    ],
                  );
                },
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: APage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton, 'push BPage'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(APage, null),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      testWidgets(
        'call pushPage with toParent=true before the initial router fails with NavigationStackError',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                builder: (context, router) {
                  return Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          navNotifier.pushPage(
                            context,
                            AppPageNode(page: BPage()),
                            toParent: true,
                          );
                        },
                        child: Text('push BPage toParent'),
                      ),
                      Expanded(child: router!)
                    ],
                  );
                },
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: APage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester
              .tap(find.widgetWithText(TextButton, 'push BPage toParent'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isInstanceOf<NavigationStackError>());
        },
      );
    });

    group('replaceLastWith', () {
      testWidgets(
        'replaceLastWith changes branch',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: DPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
              find.widgetWithText(TextButton, 'replaceLastWith favorites'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.favorites,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      )
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'replaceLastWith in nested level',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack(
                    [
                      AppPageNode(
                          page: DPage(),
                          crossroad: NavigationCrossroad(
                              activeBranch: _TestNestingBranch.shop,
                              availableBranches: {
                                _TestNestingBranch.shop: NavigationStack(
                                  [
                                    AppPageNode(page: EPage()),
                                    AppPageNode(page: GPage()),
                                  ],
                                )
                              }))
                    ],
                  ),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton, JPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                      TestNode(JPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'replaceLastWith in nested level when the branches '
        'use separate navigator keys',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: KPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: _TestNestingBranch.shop,
                        availableBranches: {
                          _TestNestingBranch.shop: NavigationStack([
                            AppPageNode(page: LPage()),
                            AppPageNode(page: OPage()),
                          ])
                        },
                      ),
                    )
                  ]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'replaceLastWith ${NPage.pageKey} from ${OPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(LPage, null),
                      TestNode(NPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );
    });

    group('popPage', () {
      testWidgets('popPage without nesting', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(page: APage()),
                  AppPageNode(page: BPage()),
                  AppPageNode(page: CPage()),
                ]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester
            .tap(find.widgetWithText(TextButton, 'pop ${CPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(APage, null),
            TestNode(BPage, null),
          ]),
        );

        await tester
            .tap(find.widgetWithText(TextButton, 'pop ${BPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(APage, null),
          ]),
        );
      });

      testWidgets(
        'popPage in nested level',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: _TestNestingBranch.shop,
                        availableBranches: {
                          _TestNestingBranch.shop: NavigationStack(
                            [
                              AppPageNode(page: EPage()),
                              AppPageNode(page: GPage()),
                            ],
                          )
                        },
                      ),
                    ),
                  ]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                      TestNode(GPage, null),
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );

          await tester.tap(
              find.widgetWithText(TextButton, 'pop from ${GPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'popPage in nested level stack with single node fails',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: DPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
              find.widgetWithText(TextButton, 'pop from ${FPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isInstanceOf<NavigationStackError>());
        },
      );

      testWidgets(
        'popPage in nested level when the branches '
        'use separate navigator keys',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack(
                    [
                      AppPageNode(
                        page: KPage(),
                        crossroad: NavigationCrossroad(
                          activeBranch: _TestNestingBranch.shop,
                          availableBranches: {
                            _TestNestingBranch.shop: NavigationStack([
                              AppPageNode(page: LPage()),
                              AppPageNode(page: NPage())
                            ])
                          },
                        ),
                      )
                    ],
                  ),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
              find.widgetWithText(TextButton, 'popPage from ${NPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(LPage, null),
                    ],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );
    });

    group('setNestingBranch', () {
      testWidgets(
          'set nesting branch with parent navigator being the root navigator fails',
          (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: APage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(
            TextButton, 'setBranch favorites from ${APage.pageKey}'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isInstanceOf<NavigationStackError>());
      });

      testWidgets(
        'set nesting branch preserves branch stacks',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: _TestNestingBranch.shop,
                        availableBranches: {
                          _TestNestingBranch.shop: NavigationStack(
                            [
                              AppPageNode(page: EPage()),
                              AppPageNode(page: GPage()),
                            ],
                          )
                        },
                      ),
                    ),
                  ]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(
              TextButton, 'expect nestingBranch shop from ${GPage.pageKey}'));

          await tester.tap(find.widgetWithText(
              TextButton, 'setBranch favorites from ${GPage.pageKey}'));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'expect nestingBranch favorites from ${HPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.favorites,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'set nesting branch of a closest child navigator',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: DPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'expect nestingBranch of child shop from ${DPage.pageKey}'));

          await tester.tap(find.widgetWithText(TextButton,
              'setNestingBranch to favorites of child from ${DPage.pageKey}'));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'expect nestingBranch of child favorites from ${DPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.favorites,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'setNestingBranch when each branch has its own router.',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: KPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [TestNode(LPage, null)],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton,
              'set branch favorites in child from ${KPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.favorites,
                  {
                    _TestNestingBranch.shop: [TestNode(LPage, null)],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(
              TextButton, 'set branch shop in child from ${KPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [TestNode(LPage, null)],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'setNestingBranch with resetStack = true.',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: _TestNestingBranch.favorites,
                        availableBranches: {
                          _TestNestingBranch.shop: NavigationStack(
                            [
                              AppPageNode(page: EPage()),
                              AppPageNode(page: GPage()),
                            ],
                          )
                        },
                      ),
                    ),
                  ]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'set nestingBranch of child shop with resetStack = true from ${DPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );

      testWidgets(
        'setNestingBranch in child with resetStack = true.',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: _TestNestingBranch.favorites,
                        availableBranches: {
                          _TestNestingBranch.shop: NavigationStack(
                            [
                              AppPageNode(page: EPage()),
                              AppPageNode(page: GPage()),
                            ],
                          )
                        },
                      ),
                    ),
                  ]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton,
              'set nestingBranch of child shop with resetStack = true from ${DPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                DPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          _TestNestingBranch.categories,
                          {
                            _TestNestingBranch.categories: [
                              TestNode(FPage, null)
                            ]
                          },
                        ),
                      ),
                    ],
                    _TestNestingBranch.favorites: [TestNode(HPage, null)],
                    _TestNestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );
        },
      );
    });

    group('replaceAllWith', () {
      testWidgets('replace all pages in child navigator', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: DPage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton,
            'replaceAllWith in child [${EPage.pageKey}, ${GPage.pageKey}] from ${DPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                    TestNode(GPage, null),
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      });

      testWidgets('replace all pages in nested stack', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: DPage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester
            .tap(find.widgetWithText(TextButton, 'replaceAllWith E, G page'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                    TestNode(GPage, null),
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      });

      testWidgets('replace all pages in the root stack', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: APage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
            find.widgetWithText(TextButton, 'replaceAllWith ${DPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      });

      testWidgets(
        'replaceAllWith in nested level when the branches '
        'use separate navigator keys',
        (tester) async {
          final navNotifier = NavigationNotifier(routes);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: ProviderContainer(
                overrides: [navigationProvider.overrideWithValue(navNotifier)],
              ),
              child: MaterialApp.router(
                routeInformationParser:
                    RoutebornRouteInfoParser<_TestNestingBranch>(
                  routes: routes,
                  initialStackBuilder: () =>
                      NavigationStack([AppPageNode(page: KPage())]),
                  page404: TestPage404(),
                ),
                routerDelegate: RoutebornRootRouterDelegate(navNotifier),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(
              TextButton, 'replaceAllWith from ${LPage.pageKey}'));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                KPage,
                TestCrossroad(
                  _TestNestingBranch.shop,
                  {
                    _TestNestingBranch.shop: [
                      TestNode(LPage, null),
                      TestNode(NPage, null)
                    ],
                    _TestNestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );
    });

    group('popUntil', () {
      testWidgets('popUntil from the root stack', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(page: APage()),
                  AppPageNode(page: BPage()),
                  AppPageNode(page: CPage()),
                ]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        //  'popUntil ${APage.pageKey} from ${CPage.pageKey}'
        await tester.tap(find.widgetWithText(
            TextButton, 'popUntil ${APage.pageKey} from ${CPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(APage, null),
          ]),
        );
      });

      testWidgets('popUntil from the nested stack', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(
                    page: DPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: _TestNestingBranch.shop,
                      availableBranches: {
                        _TestNestingBranch.shop: NavigationStack(
                          [
                            AppPageNode(page: EPage()),
                            AppPageNode(page: GPage()),
                          ],
                        )
                      },
                    ),
                  )
                ]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(
            TextButton, 'popUntil ${EPage.pageKey} from ${GPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      });
    });
  });

  group(
      'filling missing nested nodes on change '
      'to navigation notifier stack', () {
    testWidgets('pushing page fills missing nested nodes', (tester) async {
      final navNotifier = NavigationNotifier(routes);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [navigationProvider.overrideWithValue(navNotifier)],
          ),
          child: MaterialApp.router(
            routeInformationParser:
                RoutebornRouteInfoParser<_TestNestingBranch>(
              routes: routes,
              initialStackBuilder: () =>
                  NavigationStack([AppPageNode(page: DPage())]),
              page404: TestPage404(),
            ),
            routerDelegate: RoutebornRootRouterDelegate(navNotifier),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        navNotifier.rootPageNodes,
        appPageNodesStackEquals<_TestNestingBranch>([
          TestNode(
            DPage,
            TestCrossroad(
              _TestNestingBranch.shop,
              {
                _TestNestingBranch.shop: [
                  TestNode(
                    EPage,
                    TestCrossroad(
                      _TestNestingBranch.categories,
                      {
                        _TestNestingBranch.categories: [TestNode(FPage, null)]
                      },
                    ),
                  )
                ],
                _TestNestingBranch.favorites: [TestNode(HPage, null)],
                _TestNestingBranch.cart: [TestNode(IPage, null)]
              },
            ),
          ),
        ]),
      );
    });

    testWidgets(
      'pushing page with partly filled nested nodes '
      'fills the remaining missing nested nodes',
      (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(
                    page: DPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: _TestNestingBranch.shop,
                      availableBranches: {
                        _TestNestingBranch.shop: NavigationStack(
                          [
                            AppPageNode(page: EPage()),
                          ],
                        ),
                      },
                    ),
                  )
                ]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    )
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      },
    );

    testWidgets(
      'pushing page with partly filled nested nodes and empty stack '
      'fills the remaining missing nested nodes and adds initial node into empty stack.',
      (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(
                    page: DPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: _TestNestingBranch.shop,
                      availableBranches: {
                        _TestNestingBranch.shop: NavigationStack(
                          [],
                        ),
                      },
                    ),
                  )
                ]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals<_TestNestingBranch>([
            TestNode(
              DPage,
              TestCrossroad(
                _TestNestingBranch.shop,
                {
                  _TestNestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        _TestNestingBranch.categories,
                        {
                          _TestNestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    )
                  ],
                  _TestNestingBranch.favorites: [TestNode(HPage, null)],
                  _TestNestingBranch.cart: [TestNode(IPage, null)]
                },
              ),
            ),
          ]),
        );
      },
    );

    testWidgets(
      'pushing page with partly filled nested nodes '
      'that are not in routes fail',
      (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              builder: (context, child) {
                return Column(
                  children: [
                    TextButton(
                      child: Text('action'),
                      onPressed: () {
                        context.read(navigationProvider).replaceRootStackWith([
                          AppPageNode(
                            page: DPage(),
                            crossroad: NavigationCrossroad(
                              activeBranch: _TestNestingBranch.categories,
                              availableBranches: {
                                _TestNestingBranch.categories: NavigationStack(
                                  [
                                    AppPageNode(page: EPage()),
                                  ],
                                ),
                              },
                            ),
                          )
                        ]);
                      },
                    ),
                    Expanded(child: child!),
                  ],
                );
              },
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: APage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'action'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isInstanceOf<NavigationStackError>());
      },
    );

    testWidgets(
      'pushing page where a stack has page '
      'that are not in routes fail',
      (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              builder: (context, child) {
                return Column(
                  children: [
                    TextButton(
                      child: Text('action'),
                      onPressed: () {
                        context.read(navigationProvider).replaceRootStackWith([
                          AppPageNode(
                            page: DPage(),
                            crossroad: NavigationCrossroad(
                              activeBranch: _TestNestingBranch.shop,
                              availableBranches: {
                                _TestNestingBranch.shop: NavigationStack(
                                  [
                                    AppPageNode(
                                        page:
                                            APage()), // Instead of EPage is the incorrect APage
                                  ],
                                ),
                              },
                            ),
                          )
                        ]);
                      },
                    ),
                    Expanded(child: child!),
                  ],
                );
              },
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: APage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'action'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isInstanceOf<NavigationStackError>());
      },
    );

    testWidgets(
      'pushing page with crossroad where the node '
      'doesn\'t have crossroad in routes fails',
      (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              builder: (context, child) {
                return Column(
                  children: [
                    TextButton(
                      child: Text('action'),
                      onPressed: () {
                        context.read(navigationProvider).replaceRootStackWith([
                          AppPageNode(
                            page: APage(),
                            crossroad: NavigationCrossroad(
                              activeBranch: _TestNestingBranch.shop,
                              availableBranches: {
                                _TestNestingBranch.shop: NavigationStack([]),
                              },
                            ),
                          )
                        ]);
                      },
                    ),
                    Expanded(child: child!),
                  ],
                );
              },
              routeInformationParser:
                  RoutebornRouteInfoParser<_TestNestingBranch>(
                routes: routes,
                initialStackBuilder: () =>
                    NavigationStack([AppPageNode(page: APage())]),
                page404: TestPage404(),
              ),
              routerDelegate: RoutebornRootRouterDelegate(navNotifier),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'action'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isInstanceOf<NavigationStackError>());
      },
    );
  });
}

class TestPage404 extends Fake implements RoutebornPage {}

class APage extends RoutebornPage {
  static const String pageKey = 'a';

  APage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('replaceAllWith ${DPage.pageKey}'),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .replaceAllWith(context, [AppPageNode(page: DPage())]);
                },
              ),
              TextButton(
                child: Text('setBranch favorites from $pageKey'),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .setNestingBranch(context, _TestNestingBranch.favorites);
                },
              ),
              TextButton(
                child: Text(BPage.pageKey),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .pushPage(context, AppPageNode(page: BPage()));
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class BPage extends RoutebornPage {
  static const String pageKey = 'b';

  BPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text(CPage.pageKey),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .pushPage(context, AppPageNode(page: CPage()));
                },
              ),
              TextButton(
                child: Text('pop $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).popPage(context);
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class CPage extends RoutebornPage {
  static const String pageKey = 'c';

  CPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('popUntil ${APage.pageKey} from ${CPage.pageKey}'),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .popUntil(context, (page) => page.runtimeType == APage);
                },
              ),
              TextButton(
                child: Text('replace all with DPage'),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .replaceRootStackWith([AppPageNode(page: DPage())]);
                },
              ),
              TextButton(
                child: Text('pop $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).popPage(context);
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class DPage extends RoutebornPage {
  static const String pageKey = 'd';

  DPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                onPressed: () {
                  context.read(navigationProvider).replaceAllWith(
                        context,
                        [
                          AppPageNode(page: EPage()),
                          AppPageNode(page: GPage())
                        ],
                        inChildNavigator: true,
                      );
                },
                child: Text(
                    'replaceAllWith in child [${EPage.pageKey}, ${GPage.pageKey}] from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  context.read(navigationProvider).setNestingBranch(
                        context,
                        _TestNestingBranch.shop,
                        inChildNavigator: true,
                        resetBranchStack: true,
                      );
                },
                child: Text(
                    'set nestingBranch of child shop with resetStack = true from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  expect(
                    context.read(navigationProvider).getNestingBranch(
                          context,
                          inChildNavigator: true,
                        ),
                    _TestNestingBranch.favorites,
                  );
                },
                child: Text(
                    'expect nestingBranch of child favorites from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  expect(
                    context.read(navigationProvider).getNestingBranch(
                          context,
                          inChildNavigator: true,
                        ),
                    _TestNestingBranch.shop,
                  );
                },
                child: Text(
                    'expect nestingBranch of child shop from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  context.read(navigationProvider).setNestingBranch(
                        context,
                        _TestNestingBranch.favorites,
                        inChildNavigator: true,
                      );
                },
                child: Text(
                    'setNestingBranch to favorites of child from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  context.read(navigationProvider).replaceLastWith(
                        context,
                        AppPageNode(
                          page: DPage(),
                          crossroad: NavigationCrossroad(
                              activeBranch: _TestNestingBranch.favorites),
                        ),
                      );
                },
                child: Text('replaceLastWith favorites'),
              ),
              Expanded(
                child: Router(
                  routerDelegate: RoutebornNestedRouterDelegate(
                      context.read(navigationProvider)),
                ),
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class EPage extends RoutebornPage {
  static const String pageKey = 'e';

  EPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('replaceAllWith E, G page'),
                onPressed: () {
                  context.read(navigationProvider).replaceAllWith(
                    context,
                    [
                      AppPageNode(page: EPage()),
                      AppPageNode(page: GPage()),
                    ],
                  );
                },
              ),
              TextButton(
                child: Text(GPage.pageKey),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .pushPage(context, AppPageNode(page: GPage()));
                },
              ),
              TextButton(
                child: Text(BPage.pageKey),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .pushPage(context, AppPageNode(page: BPage()));
                },
              ),
              Expanded(
                child: Router(
                  routerDelegate: RoutebornNestedRouterDelegate(
                      context.read(navigationProvider)),
                ),
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class FPage extends RoutebornPage {
  static const String pageKey = 'f';

  FPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('push parent ${GPage.pageKey}'),
                onPressed: () {
                  context.read(navigationProvider).pushPage(
                      context, AppPageNode(page: GPage()),
                      toParent: true);
                },
              ),
              TextButton(
                child: Text('pop from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).popPage(context);
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class GPage extends RoutebornPage {
  static const String pageKey = 'g';

  GPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('popUntil ${EPage.pageKey} from ${GPage.pageKey}'),
                onPressed: () {
                  context.read(navigationProvider).popUntil(
                        context,
                        (page) => page.runtimeType == EPage,
                      );
                },
              ),
              TextButton(
                child: Text(
                    'setNestingBranch to shop with resetStack = true from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).setNestingBranch(
                        context,
                        _TestNestingBranch.shop,
                        resetBranchStack: true,
                      );
                },
              ),
              TextButton(
                child: Text('expect nestingBranch shop from $pageKey'),
                onPressed: () {
                  expect(
                      context
                          .read(navigationProvider)
                          .getNestingBranch(context),
                      _TestNestingBranch.shop);
                },
              ),
              TextButton(
                child: Text('setBranch favorites from $pageKey'),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .setNestingBranch(context, _TestNestingBranch.favorites);
                },
              ),
              TextButton(
                child: Text('pop from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).popPage(context);
                },
              ),
              TextButton(
                child: Text(JPage.pageKey),
                onPressed: () {
                  context
                      .read(navigationProvider)
                      .replaceLastWith(context, AppPageNode(page: JPage()));
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class HPage extends RoutebornPage {
  static const String pageKey = 'h';

  HPage()
      : super.builder(
          pageKey,
          (context) => TextButton(
            child: Text('expect nestingBranch favorites from $pageKey'),
            onPressed: () {
              expect(context.read(navigationProvider).getNestingBranch(context),
                  _TestNestingBranch.favorites);
            },
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class IPage extends RoutebornPage {
  static const String pageKey = 'i';

  IPage()
      : super.builder(
          pageKey,
          (context) => Container(),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class JPage extends RoutebornPage {
  static const String pageKey = 'j';

  JPage()
      : super.builder(
          pageKey,
          (context) => Container(),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class KPage extends RoutebornPage {
  static const String pageKey = 'k';

  KPage()
      : super.builder(
          pageKey,
          (context) => Consumer(
            builder: (context, watch, _) {
              final items = [
                _TestNestingBranch.shop,
                _TestNestingBranch.favorites
              ];
              final currentBranch = watch(navigationProvider)
                  .getNestingBranch(context, inChildNavigator: true);

              return Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: items.indexWhere((e) => e == currentBranch),
                        children: items
                            .map(
                              (branch) => Router(
                                routerDelegate: RoutebornNestedRouterDelegate(
                                  context.read(navigationProvider),
                                  branch: branch,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    TextButton(
                      child: Text('set branch shop in child from $pageKey'),
                      onPressed: () {
                        context.read(navigationProvider).setNestingBranch(
                            context, _TestNestingBranch.shop,
                            inChildNavigator: true);
                      },
                    ),
                    TextButton(
                      child:
                          Text('set branch favorites in child from $pageKey'),
                      onPressed: () {
                        context.read(navigationProvider).setNestingBranch(
                            context, _TestNestingBranch.favorites,
                            inChildNavigator: true);
                      },
                    )
                  ],
                ),
              );
            },
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class LPage extends RoutebornPage {
  static const String pageKey = 'l';

  LPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('pushPage NPage from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).pushPage(
                        context,
                        AppPageNode(page: NPage()),
                      );
                },
              ),
              TextButton(
                child: Text('replaceAllWith from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).replaceAllWith(context, [
                    AppPageNode(page: LPage()),
                    AppPageNode(page: NPage()),
                  ]);
                },
              ),
            ],
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class MPage extends RoutebornPage {
  static const String pageKey = 'm';

  MPage()
      : super.builder(
          pageKey,
          (context) => Container(),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class NPage extends RoutebornPage {
  static const String pageKey = 'n';

  NPage()
      : super.builder(
          pageKey,
          (context) => TextButton(
            child: Text('popPage from $pageKey'),
            onPressed: () {
              context.read(navigationProvider).popPage(context);
            },
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}

class OPage extends RoutebornPage {
  static const String pageKey = 'o';

  OPage()
      : super.builder(
          pageKey,
          (context) => TextButton(
            child: Text('replaceLastWith ${NPage.pageKey} from $pageKey'),
            onPressed: () {
              context
                  .read(navigationProvider)
                  .replaceLastWith(context, AppPageNode(page: NPage()));
            },
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right(pageKey);
  @override
  String getPagePath() => pageKey;
  @override
  String getPagePathBase() => pageKey;
}
