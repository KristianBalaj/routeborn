import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:routeborn/routeborn.dart';

import '../main.dart';

class HelpPage extends RoutebornPage {
  static const pagePathBase = 'help';

  HelpPage()
      : super.builder(
          pagePathBase,
          (_) => HelpPageView(),
        );

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}

class HelpPageView extends StatelessWidget {
  const HelpPageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read(navigationNotifierProvider).popPage(context);
      },
      child: Text('Pop help page'),
    );
  }
}
