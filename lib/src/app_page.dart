import 'package:dartz/dartz.dart' show Either, Tuple2;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppPage extends Page<dynamic> {
  /// Builder of the page widget.
  ///
  /// The [late final] is useful in case the builder
  /// needs to access the [AppPage] instance.
  /// In that case the builder should be initialized in the contructor body.
  late final WidgetBuilder _builder;

  final UniqueKey uniqueKey;

  set builder(WidgetBuilder builder) => _builder = builder;

  /// Use this constructor in case you need to initialize the [builder]
  /// later (for the purpose of accessing the page instance).
  ///
  /// [pageArgs] parameter is used to distinguish each page instance
  AppPage(
    String name, {
    dynamic pageArgs,
  })  : uniqueKey = UniqueKey(),
        super(
          key: _createKey(name, pageArgs),
          name: name,
        );

  /// Use this constructor in case you can initialize the [builder]
  /// in the app_initialization list (no need for page instance).
  /// [pageArgs] parameter is used to distinguish each page instance
  AppPage.builder(
    String name,
    WidgetBuilder builder, {
    dynamic pageArgs,
  })  : uniqueKey = UniqueKey(),
        super(
          key: _createKey(name, pageArgs),
          name: name,
        ) {
    this.builder = builder;
  }

  static LocalKey _createKey<T>(String name, T? pageArgs) {
    return ValueKey(pageArgs != null ? Tuple2(name, pageArgs) : name);
  }

  /// Get name of the page.
  ///
  /// The first value of the [Either] is used in case the page name is asynchronous.
  /// [null] value is for the loading state.
  /// The stream is updating when the name gets loaded.
  Either<Stream<String?>, String> getPageName(BuildContext context);

  /// This is only the page path base. E.g. pagePath = /smth/1
  /// The page path base is the one without arguments as following = /smth/
  String getPagePathBase();

  /// This is used to fill URL with the page path base and arguments.
  String getPagePath();

  @override
  Route<dynamic> createRoute(BuildContext context) =>
      MaterialPageRoute<dynamic>(
        settings: this,
        builder: _builder,
      );

  @override
  String toString() {
    return '{Hashcode: $hashCode, ${super.toString()}}';
  }
}
