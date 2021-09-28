import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/routeborn.dart';

class Page404 extends AppPage {
  static const pagePathBase = '404';

  Page404()
      : super.builder(
          pagePathBase,
          (_) => const Center(
            child: Text('404'),
          ),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}
