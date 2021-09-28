import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:routeborn/routeborn.dart';

class FavoritesPage extends AppPage {
  static const pagePathBase = 'favorites';

  FavoritesPage() : super.builder(pagePathBase, (_) => FavoritesPageView());

  @override
  Either<Stream<String?>, String> getPageName(BuildContext context) =>
      Right('');

  @override
  String getPagePath() => pagePathBase;

  @override
  String getPagePathBase() => pagePathBase;
}

class FavoritesPageView extends HookWidget {
  const FavoritesPageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Favorites'),
    );
  }
}
