import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/pages_configuration.dart';
import 'package:routeborn/src/routeborn_route_info_parser.dart';

import '../matchers/app_pages_matcher.dart';

enum _TestNestingBranch {
  shop,
  favorites,
  cart,
  categories,
}

void main() {
  final routes = <String, RouteNode<_TestNestingBranch>>{
    EPage.pageKey: RouteNode(
      Right(() => EPage()),
      routes: {
        BPage.pageKey: RouteNode(
          Left(BPage.fromPathParams),
          routes: {
            APage.pageKey: RouteNode(Right(() => APage())),
            BPage.pageKey: RouteNode(
              Left(BPage.fromPathParams),
            ),
          },
        ),
        CPage.pageKey: RouteNode(
          Left(CPage.fromPathParams),
          routes: {
            APage.pageKey: RouteNode(Right(() => APage())),
            BPage.pageKey: RouteNode(
              Left(BPage.fromPathParams),
            ),
          },
        ),
      },
    ),
    APage.pageKey: RouteNode(
      Right(() => APage()),
      nestedBranches: NestedBranches(
        defaultBranch: _TestNestingBranch.shop,
        branches: {
          _TestNestingBranch.shop: BranchInitNode(
            APage.pageKey,
            RouteNode(
              Right(() => APage()),
              nestedBranches: NestedBranches(
                defaultBranch: _TestNestingBranch.categories,
                branches: {
                  _TestNestingBranch.categories: BranchInitNode(
                    APage.pageKey,
                    RouteNode(Right(() => APage())),
                  )
                },
              ),
              routes: {
                DPage.pageKey: RouteNode(
                  Left(DPage.fromPathParams),
                ),
              },
            ),
          ),
          _TestNestingBranch.favorites: BranchInitNode(
            FPage.pageKey,
            RouteNode(
              Right(() => FPage()),
            ),
          ),
          _TestNestingBranch.cart: BranchInitNode(
            EPage.pageKey,
            RouteNode(
              Right(() => EPage()),
              routes: {
                APage.pageKey: RouteNode(Right(() => APage())),
              },
            ),
          ),
        },
      ),
      routes: {
        BPage.pageKey: RouteNode(
          Left(BPage.fromPathParams),
          routes: {
            APage.pageKey: RouteNode(Right(() => APage())),
            BPage.pageKey: RouteNode(
              Left(BPage.fromPathParams),
            ),
          },
        ),
        CPage.pageKey: RouteNode(
          Left(CPage.fromPathParams),
          routes: {
            APage.pageKey: RouteNode(Right(() => APage())),
            BPage.pageKey: RouteNode(
              Left(BPage.fromPathParams),
            ),
          },
        ),
      },
    ),
  };

  Future<PagesConfiguration<_TestNestingBranch>> routeInfo(String route) {
    return MyRouteInformationParser<_TestNestingBranch>(
      routes: routes,
      initialStackBuilder: () => NavigationStack([AppPageNode(page: EPage())]),
      page404: TestPage404(),
    ).parseRouteInformation(
      RouteInformation(location: route),
    );
  }

  group(
    'root routes (without nesting)',
    () {
      test(
        'Last page parametrized',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${BPage.pageKey}/5')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(EPage, null),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      test(
        'Parametrized page didn\'t get parameters (BPage)',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${BPage.pageKey}')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(TestPage404, null),
            ]),
          );
        },
      );

      test(
        'Multiple parametrized pages',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${BPage.pageKey}/5/${BPage.pageKey}/2')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(EPage, null),
              TestNode(BPage, null),
              TestNode(BPage, null)
            ]),
          );
        },
      );

      test(
        'CPage needs 2 query params, not just one',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${CPage.pageKey}/5/${BPage.pageKey}/2')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(TestPage404, null),
            ]),
          );
        },
      );

      test(
        'Page with multiple parameters (CPage)',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${CPage.pageKey}/5/2/${BPage.pageKey}/2')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(EPage, null),
              TestNode(CPage, null),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      test(
        'Nonexisting page in the routes should result in parsing fail',
        () async {
          expect(
            await routeInfo(
                    'http://localhost/${EPage.pageKey}/${CPage.pageKey}/5/2/${BPage.pageKey}/2/${APage.pageKey}')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(TestPage404, null),
            ]),
          );
        },
      );

      test(
        'Trailing slash in path',
        () async {
          expect(
            await routeInfo('http://localhost/${EPage.pageKey}/')
                .then((value) => value.pagesStack),
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(EPage, null),
            ]),
          );
        },
      );
    },
  );

  group(
    'nested routes',
    () {
      test(
        'Single node in the nested branch',
        () async {
          final pagesConfig = await routeInfo(
              'http://localhost/${APage.pageKey}/${EPage.pageKey}');

          expect(
            pagesConfig.appPagesStack.map((e) => e.runtimeType).toList(),
            orderedEquals(<Type>[APage, EPage]),
          );

          expect(
            pagesConfig.pagesStack,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                APage,
                TestCrossroad(
                  _TestNestingBranch.cart,
                  {
                    _TestNestingBranch.shop: [
                      // TestNode(
                      //   APage,
                      //   TestCrossroad(
                      //     _TestNestingBranch.categories,
                      //     {
                      //       _TestNestingBranch.categories: [
                      //         TestNode(APage, null),
                      //       ],
                      //     },
                      //   ),
                      // ),
                    ],
                    _TestNestingBranch.favorites: [
                      // TestNode(FPage, null),
                    ],
                    _TestNestingBranch.cart: [
                      TestNode(EPage, null),
                    ]
                  },
                ),
              ),
            ]),
          );
        },
      );

      test(
        'Single node in the nested branch parametrized without parameter returns 404 page',
        () async {
          final pagesConfig = await routeInfo(
              'http://localhost/${APage.pageKey}/${DPage.pageKey}');

          expect(
            pagesConfig.appPagesStack.map((e) => e.runtimeType).toList(),
            orderedEquals(<Type>[TestPage404]),
          );

          expect(
            pagesConfig.pagesStack,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(TestPage404, null),
            ]),
          );
        },
      );

      test(
        'Single node in nested level non-parametrized followed by root level node',
        () async {
          final pagesConfig = await routeInfo(
              'http://localhost/${APage.pageKey}/${EPage.pageKey}/${BPage.pageKey}/5');

          expect(
            pagesConfig.appPagesStack.map((e) => e.runtimeType),
            orderedEquals(<Type>[APage, EPage, BPage]),
          );

          expect(
            pagesConfig.pagesStack,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                APage,
                TestCrossroad(
                  _TestNestingBranch.cart,
                  {
                    _TestNestingBranch.shop: [
                      // TestNode(
                      //   APage,
                      //   TestCrossroad(
                      //     _TestNestingBranch.categories,
                      //     {
                      //       _TestNestingBranch.categories: [
                      //         TestNode(APage, null),
                      //       ],
                      //     },
                      //   ),
                      // ),
                    ],
                    _TestNestingBranch.favorites: [
                      // TestNode(FPage, null),
                    ],
                    _TestNestingBranch.cart: [
                      TestNode(EPage, null),
                    ]
                  },
                ),
              ),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      test(
        'Single node in nested level followed by root level node',
        () async {
          final pagesConfig = await routeInfo(
              'http://localhost/${APage.pageKey}/${FPage.pageKey}/${BPage.pageKey}/5');

          expect(
            pagesConfig.appPagesStack.map((e) => e.runtimeType),
            orderedEquals(<Type>[APage, FPage, BPage]),
          );

          expect(
            pagesConfig.pagesStack,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                APage,
                TestCrossroad(
                  _TestNestingBranch.favorites,
                  {
                    _TestNestingBranch.shop: [
                      // TestNode(
                      //   APage,
                      //   TestCrossroad(
                      //     _TestNestingBranch.categories,
                      //     {
                      //       _TestNestingBranch.categories: [
                      //         TestNode(APage, null),
                      //       ],
                      //     },
                      //   ),
                      // ),
                    ],
                    _TestNestingBranch.favorites: [
                      TestNode(FPage, null),
                    ],
                    _TestNestingBranch.cart: [
                      // TestNode(EPage, null),
                    ]
                  },
                ),
              ),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      test(
        'Multiple nodes in nested level followed by root level node',
        () async {
          final pagesConfig = await routeInfo(
              'http://localhost/${APage.pageKey}/${EPage.pageKey}/${APage.pageKey}/${BPage.pageKey}/5');

          expect(
            pagesConfig.appPagesStack.map((e) => e.runtimeType).toList(),
            orderedEquals(<Type>[APage, EPage, APage, BPage]),
          );

          expect(
            pagesConfig.pagesStack,
            appPageNodesStackEquals<_TestNestingBranch>([
              TestNode(
                APage,
                TestCrossroad(
                  _TestNestingBranch.cart,
                  {
                    _TestNestingBranch.shop: [
                      // TestNode(
                      //   APage,
                      // TestCrossroad(
                      //   _TestNestingBranch.categories,
                      //   {
                      //     _TestNestingBranch.categories: [
                      //       TestNode(APage, null),
                      //     ],
                      //   },
                      // ),
                      // ),
                    ],
                    _TestNestingBranch.favorites: [
                      // TestNode(FPage, null),
                    ],
                    _TestNestingBranch.cart: [
                      TestNode(EPage, null),
                      TestNode(APage, null),
                    ]
                  },
                ),
              ),
              TestNode(BPage, null),
            ]),
          );
        },
      );

      // test(
      //     'Path without complete nested routes. '
      //     'Parsing fills the missing nested routes '
      //     'by adding default branches in nested routes', () async {
      //   final pagesConfig = await routeInfo(
      //       'http://localhost/${APage.pageKey}/${APage.pageKey}');
      //
      //   expect(
      //     pagesConfig.appPagesStack.map((e) => e.runtimeType),
      //     orderedEquals([APage, APage, APage]),
      //   );
      //
      //   expect(
      //     pagesConfig.rootPageNodes,
      //     appPageNodesStackEquals([
      //       TestNode(
      //         APage,
      //         TestCrossroad(
      //           _TestNestingBranch.shop,
      //           {
      //             _TestNestingBranch.shop: [
      //               TestNode(
      //                 APage,
      //                 TestCrossroad(
      //                   _TestNestingBranch.categories,
      //                   {
      //                     _TestNestingBranch.categories: [
      //                       TestNode(APage, null),
      //                     ],
      //                   },
      //                 ),
      //               ),
      //             ],
      //             _TestNestingBranch.favorites: [
      //               TestNode(FPage, null),
      //             ],
      //             _TestNestingBranch.cart: [
      //               TestNode(EPage, null),
      //             ]
      //           },
      //         ),
      //       ),
      //     ]),
      //   );
      // });

      // test(
      //   'Multiple nodes in nested level followed by root level node',
      //   () async {
      //     final pagesConfig = await routeInfo(
      //         'http://localhost/${APage.pageKey}/${APage.pageKey}/${DPage.pageKey}/1/${BPage.pageKey}/5');
      //
      //     expect(
      //       pagesConfig.appPagesStack.map((e) => e.runtimeType).toList(),
      //       orderedEquals([APage, APage, DPage, BPage]),
      //     );
      //
      //     expect(
      //       pagesConfig.rootPageNodes,
      //       appPageNodesStackEquals([
      //         TestNode(
      //           APage,
      //           TestCrossroad(
      //             _TestNestingBranch.shop,
      //             {
      //               _TestNestingBranch.shop: [
      //                 TestNode(APage, null),
      //                 TestNode(DPage, null),
      //               ],
      //               _TestNestingBranch.favorites: [],
      //             },
      //           ),
      //         ),
      //         TestNode(BPage, null),
      //       ]),
      //     );
      //   },
      // );
      //
      // test(
      //   'Nesting level of 2 followed by parent level node and root level node',
      //   () async {
      //     final pagesConfig = await routeInfo(
      //         'http://localhost/${APage.pageKey}/${APage.pageKey}/${APage.pageKey}/${DPage.pageKey}/1/${BPage.pageKey}/5');
      //
      //     expect(
      //       pagesConfig.appPagesStack.map((e) => e.runtimeType).toList(),
      //       orderedEquals([APage, APage, APage, DPage, BPage]),
      //     );
      //
      //     expect(
      //       pagesConfig.rootPageNodes,
      //       appPageNodesStackEquals([
      //         TestNode(
      //           APage,
      //           TestCrossroad(
      //             _TestNestingBranch.shop,
      //             {
      //               _TestNestingBranch.shop: [
      //                 TestNode(
      //                   APage,
      //                   TestCrossroad(
      //                     _TestNestingBranch.categories,
      //                     {
      //                       _TestNestingBranch.categories: [
      //                         TestNode(APage, null),
      //                       ],
      //                     },
      //                   ),
      //                 ),
      //                 TestNode(DPage, null),
      //               ],
      //               _TestNestingBranch.favorites: [],
      //             },
      //           ),
      //         ),
      //         TestNode(BPage, null),
      //       ]),
      //     );
      //   },
      // );
    },
  );
}

class APage extends Fake implements AppPage {
  static const String pageKey = 'a';
}

class BPage extends Fake implements AppPage {
  static const String pageKey = 'b';
  BPage(int param);

  static Tuple2<AppPage, List<String>> fromPathParams(
    List<String> remainingPathArguments,
  ) {
    if (remainingPathArguments.isNotEmpty) {
      final res = int.tryParse(remainingPathArguments.first);
      if (res != null) {
        return Tuple2(BPage(res), remainingPathArguments.skip(1).toList());
      }
    }

    return Tuple2(TestPage404(), remainingPathArguments);
  }
}

class CPage extends Fake implements AppPage {
  static const String pageKey = 'c';
  CPage(int param, int param2);

  static Tuple2<AppPage, List<String>> fromPathParams(
    List<String> remainingPathArguments,
  ) {
    if (remainingPathArguments.length >= 2) {
      final param1 = int.tryParse(remainingPathArguments[0]);
      final param2 = int.tryParse(remainingPathArguments[1]);
      if (param1 != null && param2 != null) {
        return Tuple2(
          CPage(param1, param2),
          remainingPathArguments.skip(2).toList(),
        );
      }
    }

    return Tuple2(TestPage404(), remainingPathArguments);
  }
}

class DPage extends Fake implements AppPage {
  static const String pageKey = 'd';
  DPage(int param);

  static Tuple2<AppPage, List<String>> fromPathParams(
    List<String> remainingPathArguments,
  ) {
    if (remainingPathArguments.isNotEmpty) {
      final res = int.tryParse(remainingPathArguments.first);
      if (res != null) {
        return Tuple2(DPage(res), remainingPathArguments.skip(1).toList());
      }
    }

    return Tuple2(TestPage404(), remainingPathArguments);
  }
}

class EPage extends Fake implements AppPage {
  static const String pageKey = 'e';
}

class FPage extends Fake implements AppPage {
  static const String pageKey = 'f';
}

class TestPage404 extends Fake implements AppPage {}
