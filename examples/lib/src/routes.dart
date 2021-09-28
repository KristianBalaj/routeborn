import 'package:examples/src/favorites_page.dart';
import 'package:examples/src/help_page.dart';
import 'package:examples/src/home_page.dart';
import 'package:examples/src/product_detail_page.dart';
import 'package:examples/src/shop_page.dart';
import 'package:routeborn/routeborn.dart';

enum NestingBranch { shop, favorites }

final routes = <String, RouteNode<NestingBranch>>{
  HomePage.pagePathBase: RouteNode(
    NonParametrizedPage(() => HomePage()),
    nestedBranches: NestedBranches(
      defaultBranch: NestingBranch.shop,
      branches: {
        NestingBranch.shop: BranchInitNode(
          ShopPage.pagePathBase,
          RouteNode(
            NonParametrizedPage(() => ShopPage()),
            routes: {
              ProductDetailPage.pagePathBase:
                  RouteNode(NonParametrizedPage(() => ProductDetailPage()))
            },
          ),
        ),
        NestingBranch.favorites: BranchInitNode(
          FavoritesPage.pagePathBase,
          RouteNode(NonParametrizedPage(() => FavoritesPage())),
        )
      },
    ),
    routes: {
      HelpPage.pagePathBase: RouteNode(NonParametrizedPage(() => HelpPage()))
    },
  ),
};
