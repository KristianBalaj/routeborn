import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/routeborn_page.dart';

class FakePage extends Fake implements RoutebornPage {}

class FakeFavoritesPage extends Fake implements RoutebornPage {}

class FakeCartPage extends Fake implements RoutebornPage {}

class FakeCategoriesPage extends Fake implements RoutebornPage {}

enum _TestNestingBranch {
  shop,
  favorites,
  cart,
  categories,
}

void main() {
  test(
    'activeStackFlattened',
    () async {
      final stack = NavigationStack<_TestNestingBranch>([
        AppPageNode(
          page: FakePage(),
          crossroad: NavigationCrossroad(
            activeBranch: _TestNestingBranch.cart,
            availableBranches: {
              _TestNestingBranch.shop: NavigationStack(
                [AppPageNode(page: FakePage())],
              ),
              _TestNestingBranch.cart: NavigationStack(
                [
                  AppPageNode(
                    page: FakeCartPage(),
                    crossroad: NavigationCrossroad(
                      activeBranch: _TestNestingBranch.favorites,
                      availableBranches: {
                        _TestNestingBranch.favorites: NavigationStack(
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
                      activeBranch: _TestNestingBranch.favorites,
                      availableBranches: {
                        _TestNestingBranch.favorites: NavigationStack(
                          [
                            AppPageNode(
                              page: FakeFavoritesPage(),
                              crossroad: NavigationCrossroad(
                                activeBranch: _TestNestingBranch.categories,
                                availableBranches: {
                                  _TestNestingBranch.categories:
                                      NavigationStack(
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
      final stack =
          NavigationStack<_TestNestingBranch>([AppPageNode(page: FakePage())]);

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
  //         activeBranch: _TestNestingBranch.cart,
  //         availableBranches: {
  //           _TestNestingBranch.shop:
  //               NavigationStack([AppPageNode(page: FakePage())]),
  //           _TestNestingBranch.cart: NavigationStack(
  //             [
  //               AppPageNode(page: FakePage()),
  //               AppPageNode(
  //                 page: FakePage(),
  //                 crossroad: NavigationCrossroad(
  //                   activeBranch: _TestNestingBranch.favorites,
  //                   availableBranches: {
  //                     _TestNestingBranch.favorites: NavigationStack([
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
