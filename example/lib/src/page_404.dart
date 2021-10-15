import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/routeborn.dart';

class Page404 extends RoutebornPage {
  static const pagePathBase = '404';

  Page404()
      : super.builder(
          pagePathBase,
          (_) => const Center(
            child: Text('404'),
          ),
        );

  @override
  Either<ValueListenable<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}
