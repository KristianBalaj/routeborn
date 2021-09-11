import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/routeborn_route_info_parser.dart';
import 'package:routeborn/src/router_delegates/routeborn_nested_router_delegate.dart';
import 'package:routeborn/src/router_delegates/routeborn_root_router_delegate.dart';

import '../matchers/app_pages_matcher.dart';

final navigationProvider =
    Provider<NavigationNotifier>((_) => throw UnimplementedError());

void main() {
  final routes = <String, RouteNode>{
    APage.pageKey: RouteNode(
      Right(() => APage()),
      routes: <String, RouteNode>{
        BPage.pageKey: RouteNode(
          Right(() => BPage()),
          routes: <String, RouteNode>{
            CPage.pageKey: RouteNode(Right(() => CPage())),
          },
        ),
      },
    ),
    DPage.pageKey: RouteNode(
      Right(() => DPage()),
      nestedBranches: NestedBranches(
        defaultBranch: NestingBranch.shop,
        branches: {
          NestingBranch.shop: BranchInitNode(
            EPage.pageKey,
            RouteNode(
              Right(() => EPage()),
              nestedBranches: NestedBranches(
                defaultBranch: NestingBranch.categories,
                branches: {
                  NestingBranch.categories: BranchInitNode(
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
          NestingBranch.favorites: BranchInitNode(
            HPage.pageKey,
            RouteNode(
              Right(() => HPage()),
            ),
          ),
          NestingBranch.cart: BranchInitNode(
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
        defaultBranch: NestingBranch.shop,
        branches: {
          NestingBranch.shop: BranchInitNode(
            LPage.pageKey,
            RouteNode(
              Right(() => LPage()),
              routes: {
                NPage.pageKey: RouteNode(Right(() => NPage())),
              },
            ),
          ),
          NestingBranch.favorites:
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(APage, null),
              TestNode(BPage, null),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton, CPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals([
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
              routeInformationParser: MyRouteInformationParser(
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
          appPageNodesStackEquals([
            TestNode(
              DPage,
              TestCrossroad(
                NestingBranch.shop,
                {
                  NestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        NestingBranch.categories,
                        {
                          NestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                    TestNode(GPage, null)
                  ],
                  NestingBranch.favorites: [TestNode(HPage, null)],
                  NestingBranch.cart: [TestNode(IPage, null)]
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(
                KPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(LPage, null),
                      TestNode(NPage, null)
                    ],
                    NestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.favorites,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      )
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
                routeInformationParser: MyRouteInformationParser(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack(
                    [
                      AppPageNode(
                          page: DPage(),
                          crossroad: NavigationCrossroad(
                              activeBranch: NestingBranch.shop,
                              availableBranches: {
                                NestingBranch.shop: NavigationStack(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton, JPage.pageKey));
          await tester.pumpAndSettle();

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                      TestNode(JPage, null)
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
              routeInformationParser: MyRouteInformationParser(
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
          appPageNodesStackEquals([
            TestNode(APage, null),
            TestNode(BPage, null),
          ]),
        );

        await tester
            .tap(find.widgetWithText(TextButton, 'pop ${BPage.pageKey}'));
        await tester.pumpAndSettle();

        expect(
          navNotifier.rootPageNodes,
          appPageNodesStackEquals([
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
                routeInformationParser: MyRouteInformationParser(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: NestingBranch.shop,
                        availableBranches: {
                          NestingBranch.shop: NavigationStack(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                      TestNode(GPage, null),
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
                routeInformationParser: MyRouteInformationParser(
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
                routeInformationParser: MyRouteInformationParser(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack(
                    [
                      AppPageNode(
                        page: KPage(),
                        crossroad: NavigationCrossroad(
                          activeBranch: NestingBranch.shop,
                          availableBranches: {
                            NestingBranch.shop: NavigationStack([
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
            appPageNodesStackEquals([
              TestNode(
                KPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [
                      TestNode(LPage, null),
                    ],
                    NestingBranch.favorites: [TestNode(MPage, null)],
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
              routeInformationParser: MyRouteInformationParser(
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
                routeInformationParser: MyRouteInformationParser(
                  routes: routes,
                  initialStackBuilder: () => NavigationStack([
                    AppPageNode(
                      page: DPage(),
                      crossroad: NavigationCrossroad(
                        activeBranch: NestingBranch.shop,
                        availableBranches: {
                          NestingBranch.shop: NavigationStack(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.favorites,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                      TestNode(GPage, null)
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(
                DPage,
                TestCrossroad(
                  NestingBranch.favorites,
                  {
                    NestingBranch.shop: [
                      TestNode(
                        EPage,
                        TestCrossroad(
                          NestingBranch.categories,
                          {
                            NestingBranch.categories: [TestNode(FPage, null)]
                          },
                        ),
                      ),
                    ],
                    NestingBranch.favorites: [TestNode(HPage, null)],
                    NestingBranch.cart: [TestNode(IPage, null)]
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
                routeInformationParser: MyRouteInformationParser(
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
            appPageNodesStackEquals([
              TestNode(
                KPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [TestNode(LPage, null)],
                    NestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(TextButton,
              'set branch favorites in child from ${KPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals([
              TestNode(
                KPage,
                TestCrossroad(
                  NestingBranch.favorites,
                  {
                    NestingBranch.shop: [TestNode(LPage, null)],
                    NestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );

          await tester.tap(find.widgetWithText(
              TextButton, 'set branch shop in child from ${KPage.pageKey}'));

          expect(
            navNotifier.rootPageNodes,
            appPageNodesStackEquals([
              TestNode(
                KPage,
                TestCrossroad(
                  NestingBranch.shop,
                  {
                    NestingBranch.shop: [TestNode(LPage, null)],
                    NestingBranch.favorites: [TestNode(MPage, null)],
                  },
                ),
              ),
            ]),
          );
        },
      );
    });

    group('replaceAllWith', () {
      testWidgets('replace all pages in nested stack', (tester) async {
        final navNotifier = NavigationNotifier(routes);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: ProviderContainer(
              overrides: [navigationProvider.overrideWithValue(navNotifier)],
            ),
            child: MaterialApp.router(
              routeInformationParser: MyRouteInformationParser(
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
          appPageNodesStackEquals([
            TestNode(
              DPage,
              TestCrossroad(
                NestingBranch.shop,
                {
                  NestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        NestingBranch.categories,
                        {
                          NestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                    TestNode(GPage, null),
                  ],
                  NestingBranch.favorites: [TestNode(HPage, null)],
                  NestingBranch.cart: [TestNode(IPage, null)]
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
              routeInformationParser: MyRouteInformationParser(
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
          appPageNodesStackEquals([
            TestNode(
              DPage,
              TestCrossroad(
                NestingBranch.shop,
                {
                  NestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        NestingBranch.categories,
                        {
                          NestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    ),
                  ],
                  NestingBranch.favorites: [TestNode(HPage, null)],
                  NestingBranch.cart: [TestNode(IPage, null)]
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
            routeInformationParser: MyRouteInformationParser(
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
        appPageNodesStackEquals([
          TestNode(
            DPage,
            TestCrossroad(
              NestingBranch.shop,
              {
                NestingBranch.shop: [
                  TestNode(
                    EPage,
                    TestCrossroad(
                      NestingBranch.categories,
                      {
                        NestingBranch.categories: [TestNode(FPage, null)]
                      },
                    ),
                  )
                ],
                NestingBranch.favorites: [TestNode(HPage, null)],
                NestingBranch.cart: [TestNode(IPage, null)]
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
              routeInformationParser: MyRouteInformationParser(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(
                    page: DPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: NestingBranch.shop,
                      availableBranches: {
                        NestingBranch.shop: NavigationStack(
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
          appPageNodesStackEquals([
            TestNode(
              DPage,
              TestCrossroad(
                NestingBranch.shop,
                {
                  NestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        NestingBranch.categories,
                        {
                          NestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    )
                  ],
                  NestingBranch.favorites: [TestNode(HPage, null)],
                  NestingBranch.cart: [TestNode(IPage, null)]
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
              routeInformationParser: MyRouteInformationParser(
                routes: routes,
                initialStackBuilder: () => NavigationStack([
                  AppPageNode(
                    page: DPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: NestingBranch.shop,
                      availableBranches: {
                        NestingBranch.shop: NavigationStack(
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
          appPageNodesStackEquals([
            TestNode(
              DPage,
              TestCrossroad(
                NestingBranch.shop,
                {
                  NestingBranch.shop: [
                    TestNode(
                      EPage,
                      TestCrossroad(
                        NestingBranch.categories,
                        {
                          NestingBranch.categories: [TestNode(FPage, null)]
                        },
                      ),
                    )
                  ],
                  NestingBranch.favorites: [TestNode(HPage, null)],
                  NestingBranch.cart: [TestNode(IPage, null)]
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
                              activeBranch: NestingBranch.categories,
                              availableBranches: {
                                NestingBranch.categories: NavigationStack(
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
              routeInformationParser: MyRouteInformationParser(
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
                              activeBranch: NestingBranch.shop,
                              availableBranches: {
                                NestingBranch.shop: NavigationStack(
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
              routeInformationParser: MyRouteInformationParser(
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
                              activeBranch: NestingBranch.shop,
                              availableBranches: {
                                NestingBranch.shop: NavigationStack([]),
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
              routeInformationParser: MyRouteInformationParser(
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

class TestPage404 extends Fake implements AppPage {}

class APage extends AppPage {
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
                  context.read(navigationProvider).setCurrentNestingBranch(
                      context, NestingBranch.favorites);
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

class BPage extends AppPage {
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

class CPage extends AppPage {
  static const String pageKey = 'c';

  CPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
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

class DPage extends AppPage {
  static const String pageKey = 'd';

  DPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                onPressed: () {
                  expect(
                    context.read(navigationProvider).getCurrentNestingBranch(
                          context,
                          inChildNavigator: true,
                        ),
                    NestingBranch.favorites,
                  );
                },
                child: Text(
                    'expect nestingBranch of child favorites from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  expect(
                    context.read(navigationProvider).getCurrentNestingBranch(
                          context,
                          inChildNavigator: true,
                        ),
                    NestingBranch.shop,
                  );
                },
                child: Text(
                    'expect nestingBranch of child shop from ${DPage.pageKey}'),
              ),
              TextButton(
                onPressed: () {
                  context.read(navigationProvider).setCurrentNestingBranch(
                        context,
                        NestingBranch.favorites,
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
                              activeBranch: NestingBranch.favorites),
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

class EPage extends AppPage {
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

class FPage extends AppPage {
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

class GPage extends AppPage {
  static const String pageKey = 'g';

  GPage()
      : super.builder(
          pageKey,
          (context) => Column(
            children: [
              TextButton(
                child: Text('expect nestingBranch shop from $pageKey'),
                onPressed: () {
                  expect(
                      context
                          .read(navigationProvider)
                          .getCurrentNestingBranch(context),
                      NestingBranch.shop);
                },
              ),
              TextButton(
                child: Text('setBranch favorites from $pageKey'),
                onPressed: () {
                  context.read(navigationProvider).setCurrentNestingBranch(
                      context, NestingBranch.favorites);
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

class HPage extends AppPage {
  static const String pageKey = 'h';

  HPage()
      : super.builder(
          pageKey,
          (context) => TextButton(
            child: Text('expect nestingBranch favorites from $pageKey'),
            onPressed: () {
              expect(
                  context
                      .read(navigationProvider)
                      .getCurrentNestingBranch(context),
                  NestingBranch.favorites);
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

class IPage extends AppPage {
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

class JPage extends AppPage {
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

class KPage extends AppPage {
  static const String pageKey = 'k';

  KPage()
      : super.builder(
          pageKey,
          (context) => Consumer(
            builder: (context, watch, _) {
              final items = [NestingBranch.shop, NestingBranch.favorites];
              final currentBranch = watch(navigationProvider)
                  .getCurrentNestingBranch(context, inChildNavigator: true);

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
                        context
                            .read(navigationProvider)
                            .setCurrentNestingBranch(
                                context, NestingBranch.shop,
                                inChildNavigator: true);
                      },
                    ),
                    TextButton(
                      child:
                          Text('set branch favorites in child from $pageKey'),
                      onPressed: () {
                        context
                            .read(navigationProvider)
                            .setCurrentNestingBranch(
                                context, NestingBranch.favorites,
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

class LPage extends AppPage {
  static const String pageKey = 'l';

  LPage()
      : super.builder(
          pageKey,
          (context) => TextButton(
            child: Text('pushPage NPage from $pageKey'),
            onPressed: () {
              context.read(navigationProvider).pushPage(
                    context,
                    AppPageNode(page: NPage()),
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

class MPage extends AppPage {
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

class NPage extends AppPage {
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
