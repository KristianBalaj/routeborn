import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/navigation_notifier.dart';

class FakePage extends Fake implements AppPage {}

class FakeFavoritesPage extends Fake implements AppPage {}

class FakeCartPage extends Fake implements AppPage {}

class FakeCategoriesPage extends Fake implements AppPage {}

void main() {
  test(
    'activeStackFlattened',
    () async {
      final stack = NavigationStack([
        AppPageNode(
          page: FakePage(),
          crossroad: NavigationCrossroad(
            activeBranch: NestingBranch.cart,
            availableBranches: {
              NestingBranch.shop: NavigationStack(
                [AppPageNode(page: FakePage())],
              ),
              NestingBranch.cart: NavigationStack(
                [
                  AppPageNode(
                    page: FakeCartPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: NestingBranch.favorites,
                      availableBranches: {
                        NestingBranch.favorites: NavigationStack(
                          [
                            AppPageNode(page: FakeFavoritesPage()),
                          ],
                        )
                      },
                    ),
                  ),
                  AppPageNode(
                    page: FakeCartPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: NestingBranch.favorites,
                      availableBranches: {
                        NestingBranch.favorites: NavigationStack(
                          [
                            AppPageNode(
                              page: FakeFavoritesPage(),
                              crossroad: NavigationCrossroad(
                                activeBranch: NestingBranch.categories,
                                availableBranches: {
                                  NestingBranch.categories: NavigationStack(
                                    [
                                      AppPageNode(page: FakeCategoriesPage()),
                                    ],
                                  )
                                },
                              ),
                            ),
                          ],
                        )
                      },
                    ),
                  ),
                ],
              ),
            },
          ),
        )
      ]);

      expect(
        stack.activeStackFlattened().map((e) => e.runtimeType).toList(),
        [
          FakePage,
          FakeCartPage,
          FakeFavoritesPage,
          FakeCartPage,
          FakeFavoritesPage,
          FakeCategoriesPage
        ],
      );
    },
  );

  test(
    'activeStackFlattened with single page in stack',
    () async {
      final stack = NavigationStack([AppPageNode(page: FakePage())]);

      expect(stack.activeStackFlattened().map((e) => e.runtimeType).toList(),
          [FakePage]);
    },
  );

  // test(
  //   'copyWithNestedStack replaces the correct stack',
  //   () async {
  //     var node = AppPageNode(
  //       page: FakePage(),
  //       crossroad: NavigationCrossroad(
  //         activeBranch: NestingBranch.cart,
  //         availableBranches: {
  //           NestingBranch.shop:
  //               NavigationStack([AppPageNode(page: FakePage())]),
  //           NestingBranch.cart: NavigationStack(
  //             [
  //               AppPageNode(page: FakePage()),
  //               AppPageNode(
  //                 page: FakePage(),
  //                 crossroad: NavigationCrossroad(
  //                   activeBranch: NestingBranch.favorites,
  //                   availableBranches: {
  //                     NestingBranch.favorites: NavigationStack([
  //                       AppPageNode(page: FakePage()),
  //                     ])
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         },
  //       ),
  //     ).copyWithNestedStack(
  //       [
  //         AppPageNode(page: FakePage()),
  //         AppPageNode(page: FakePage()),
  //         AppPageNode(page: FakePage()),
  //       ],
  //       1,
  //     );
  //
  //     expect(
  //       node
  //           .wholeNestedStack()
  //           .map((e) => e.map((e) => e.page.runtimeType).toList())
  //           .toList(),
  //       [
  //         [FakePage, FakePage],
  //         [FakePage, FakePage, FakePage],
  //       ],
  //     );
  //
  //     node = node.copyWithNestedStack([AppPageNode(page: FakePage())], 0);
  //
  //     expect(
  //       node
  //           .wholeNestedStack()
  //           .map((e) => e.map((e) => e.page.runtimeType).toList())
  //           .toList(),
  //       [
  //         [FakePage]
  //       ],
  //     );
  //   },
  // );
}
