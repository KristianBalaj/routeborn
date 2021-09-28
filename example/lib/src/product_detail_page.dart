import 'package:dartz/dartz.dart';
import 'package:examples/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:routeborn/routeborn.dart';

class ProductDetailPage extends RoutebornPage {
  static const pagePathBase = 'product_detail';

  ProductDetailPage()
      : super.builder(pagePathBase, (_) => ProductDetailPageView());

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}

class ProductDetailPageView extends StatelessWidget {
  const ProductDetailPageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read(navigationNotifierProvider).popPage(context);
          },
          child: Text('Pop product detail'),
        ),
      ),
    );
  }
}
