import 'dart:io';

import 'package:dartz/dartz.dart' show Either, Left, Tuple2;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// This is the base [Page] type used for defining pages when
/// using the routeborn package.
abstract class RoutebornPage extends Page<dynamic> {
  /// Builder of the page widget.
  ///
  /// The [late final] is useful in case the builder
  /// needs to access the [RoutebornPage] instance.
  /// In that case the builder should be initialized in the contructor body.
  late final WidgetBuilder _builder;

  set builder(WidgetBuilder builder) => _builder = builder;

  /// Use this constructor in case you need to initialize the [builder]
  /// later (for the purpose of accessing the page instance).
  ///
  /// [pageArgs] parameter is used to distinguish each page instance
  RoutebornPage(
    String name, {
    dynamic pageArgs,
  }) : super(
          key: _createKey(name, pageArgs),
          name: name,
        );

  /// Use this constructor in case you can initialize the [builder]
  /// in the app_initialization list (no need for page instance).
  /// [pageArgs] parameter is used to distinguish each page instance
  RoutebornPage.builder(
    String name,
    WidgetBuilder builder, {
    dynamic pageArgs,
  }) : super(
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
  Either<ValueListenable<String?>, String> getPageName(BuildContext context);

  /// This is only the page path base. E.g. pagePath = /smth/1
  /// The page path base is the one without arguments as following = /smth/
  String getPagePathBase();

  /// This is used to fill URL with the page path base and arguments.
  String getPagePath();

  @override
  Route<dynamic> createRoute(BuildContext context) {
    if (kIsWeb) {
      return PageRouteBuilder<dynamic>(
        settings: this,
        pageBuilder: (context, _, __) => _builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    } else {
      if (Platform.isIOS) {
        return CupertinoPageRoute<dynamic>(
          settings: this,
          builder: _builder,
        );
      } else {
        return MaterialPageRoute<dynamic>(
          settings: this,
          builder: _builder,
        );
      }
    }
  }

  @override
  String toString() {
    return '{Hashcode: $hashCode, ${super.toString()}}';
  }
}

typedef SetPageNameCallback = void Function(String pageName);

mixin UpdatablePageNameMixin on RoutebornPage {
  final _pageNameNotifier = ValueNotifier<String?>(null);

  void setPageName(
    BuildContext context,
    String pageName,
  ) {
    final pageSettings = ModalRoute.of(context)?.settings;

    assert(() {
      if (pageSettings == null) {
        throw FlutterError('Given context has no route');
      }
      return true;
    }());

    assert(() {
      if (pageSettings is! UpdatablePageNameMixin) {
        throw FlutterError(
            'Route of this context is not of type AsyncPageNameMixin. '
            'You cannot set page name of such page.'
            ' Add the AsyncPageNameMixing to the page.');
      }
      return true;
    }());

    if ((pageSettings as UpdatablePageNameMixin)._pageNameNotifier.value !=
        pageName) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        pageSettings._pageNameNotifier.value = pageName;
      });
    }
  }

  @override
  @nonVirtual
  Either<ValueListenable<String?>, String> getPageName(BuildContext context) {
    return Left(_pageNameNotifier);
  }
}
