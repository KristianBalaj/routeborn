import 'package:dartz/dartz.dart';
import 'package:examples/main.dart';
import 'package:examples/src/product_detail_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:routeborn/routeborn.dart';

class ShopPage extends RoutebornPage {
  static const pagePathBase = 'shop';

  ShopPage() : super.builder(pagePathBase, (_) => ShopPageView());

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}

class ShopPageView extends HookWidget {
  const ShopPageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Shop'),
        ElevatedButton(
          onPressed: () {
            context
                .read(navigationNotifierProvider)
                .pushPage(context, AppPageNode(page: ProductDetailPage()));
          },
          child: Text('Push product detail'),
        )
      ],
    );
  }
}
