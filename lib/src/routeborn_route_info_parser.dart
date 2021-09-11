import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/pages_configuration.dart';

typedef ParametrizedPage = Left<
    Tuple2<AppPage, List<String>> Function(List<String>), AppPage Function()>;
typedef NonParametrizedPage = Right<
    Tuple2<AppPage, List<String>> Function(List<String>), AppPage Function()>;

class RouteNode {
  /// Builder of current node's [AppPage].
  /// The [Left] argument is path parametrized page builder and
  /// the [Right] one is the page builder without parameters.
  final Either<Tuple2<AppPage, List<String>> Function(List<String>),
      AppPage Function()> appPageBuilder;

  /// These are the following pages that go after current page.
  ///
  /// These pages fully overlap current node's page and use the same [Router].
  ///
  /// There are no following pages when [null].
  final Map<String, RouteNode>? routes;

  /// These go always before the [routes].
  /// These are visualized using a nested [Router] inside current page.
  ///
  /// These don't have to fully overlap the current page.
  ///
  /// There are no nested branches when [null].
  ///
  /// NOTICE: when a node has nested routes, there cannot be
  /// the node displayed only by itself. Nested routes need to be displayed, too.
  /// Meaning that the URL has to contain one of the nested branches
  /// with at least one page in the nested stack.
  /// This applies recursively to the nested branch nodes, too.
  final NestedBranches? nestedBranches;

  RouteNode(
    this.appPageBuilder, {
    this.routes,
    this.nestedBranches,
  }) : assert(() {
          _checkNodeTreeDeterminism(routes, nestedBranches);
          return true;
        }());

  static void _checkNodeTreeDeterminism(
    Map<String, RouteNode>? routes,
    NestedBranches? nestedBranches,
  ) {
    const baseErrText = 'Nodes tree is non deterministic. '
        'There are the same keys in the routes and nestedBranches initial node keys. '
        'This causes non-determinism when navigating via URL and therefore is not accepted. ';

    if (nestedBranches != null) {
      /// when any of the nested branches has the same initialNode key
      if (nestedBranches.branches.length !=
          nestedBranches.branches.entries
              .map((e) => e.value.nodePathKey)
              .toSet()
              .length) {
        throw FlutterError('$baseErrText\n'
            'Nested branches initial node keys are duplicated: ${nestedBranches.branches.entries.map((e) => e.value.nodePathKey).toList()}');
      }

      for (var e in nestedBranches.branches.values) {
        _checkNodeTreeDeterminism(e.node.routes, e.node.nestedBranches);
      }
    }
    if (routes != null) {
      for (var e in routes.values) {
        _checkNodeTreeDeterminism(e.routes, e.nestedBranches);
      }
    }
    if (nestedBranches != null && routes != null) {
      if (nestedBranches.branches.values
          .any((element) => routes.keys.contains(element.nodePathKey))) {
        throw FlutterError('$baseErrText\n'
            'Nested branches initial keys overlap with routes keys.\n'
            'Branches initial keys: ${nestedBranches.branches.values.map((e) => e.nodePathKey).toList()}\n'
            'Routes keys: ${routes.keys}.');
      }
    }
  }
}

class NestedBranches {
  /// In case there is no nested branch in the path.
  /// Then the path is filled with the default branch
  /// taking the first page in the branch's stack.
  ///
  /// NOTICE: because of this the first page in the branch stack
  /// needs to be non parametrized.
  /// The path param cannot be automatically derived.
  final NestingBranch defaultBranch;

  final Map<NestingBranch, BranchInitNode> branches;

  NestedBranches({
    required this.branches,
    required this.defaultBranch,
  })  : assert(branches.containsKey(defaultBranch)),
        assert(() {
          if (!branches.entries.every(
            (e) => e.value.node.appPageBuilder.isRight(), // NonParametrized
          )) {
            throw FlutterError(
                'Every initial node of a branch has to be non-parametrized');
          }
          return true;
        }());
}

class BranchInitNode {
  final String nodePathKey;
  final RouteNode node;

  BranchInitNode(this.nodePathKey, this.node);
}

class _PathSegmentsWrapper {
  List<String> pathSegments;

  _PathSegmentsWrapper(this.pathSegments);
}

class MyRouteInformationParser
    extends RouteInformationParser<PagesConfiguration> {
  final Map<String, RouteNode> routes;
  final NavigationStack Function() initialStackBuilder;

  final AppPage page404;

  MyRouteInformationParser({
    required this.routes,
    required this.initialStackBuilder,
    required this.page404,
  });

  static NestingBranch? _nestedBranchFromSegment(
    RouteNode node,
    String? pathSegment,
  ) {
    final branch = node.nestedBranches?.branches.entries
            .where((e) => e.value.nodePathKey == pathSegment) ??
        [];
    if (branch.isEmpty) return null;
    return branch.first.key;
  }

  static NavigationStack _parsePathSegments(
    List<String> segments,
    Map<String, RouteNode> routes,
    AppPage page404,
  ) {
    Iterable<AppPageNode> _parse(
      _PathSegmentsWrapper segments,
      Map<String, RouteNode> routes, {
      required bool isNested,
    }) sync* {
      if (segments.pathSegments.isEmpty) {
        yield* [];
      } else {
        final currentNode = routes[segments.pathSegments.first];

        if (currentNode == null) {
          /// When stack not nested (root level), then return 404.
          /// In case nested, it doesn't matter that it didn't find any node.
          /// It can be found in ancestory stacks.
          if (!isNested) {
            yield AppPageNode(page: page404);
          }
        } else {
          /// Remove the segment only when has node for that segment.
          segments.pathSegments = segments.pathSegments.skip(1).toList();

          final page = currentNode.appPageBuilder.fold(
            (l) {
              final res = l(segments.pathSegments);
              segments.pathSegments = res.value2;
              return res.value1;
            },
            (r) => r(),
          );

          // if (currentNode.nestedBranches != null) {
          final branch = _nestedBranchFromSegment(
            currentNode,
            segments.pathSegments.isEmpty ? null : segments.pathSegments.first,
          );

          if (branch != null) {
            /// Filling a nested stack by path value and the others by defaults.
            final branchInitNode =
                currentNode.nestedBranches!.branches[branch]!;

            final nested = _parse(
              segments,
              {branchInitNode.nodePathKey: branchInitNode.node},
              isNested: true,
            ).toList();

            yield* [
              AppPageNode(
                page: page,
                crossroad: NavigationCrossroad(
                  activeBranch: branch,
                  availableBranches: currentNode.nestedBranches!.branches.map(
                    (key, value) => MapEntry(
                      key,
                      NavigationStack(key == branch ? nested : []),
                    ),
                  ),
                ),
              ),
              ..._parse(
                segments,
                currentNode.routes ?? {},
                isNested: isNested,
              ),
            ];
          } else {
            yield* [
              AppPageNode(page: page),
              ..._parse(
                segments,
                currentNode.routes ?? {},
                isNested: isNested,
              ),
            ];
          }
        }
      }
    }

    final wrapper = _PathSegmentsWrapper(
      segments.where((e) => e.trim().isNotEmpty).toList(),
    );
    return NavigationStack(_parse(wrapper, routes, isNested: false).toList());
  }

  @override
  Future<PagesConfiguration> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = Uri.parse(routeInformation.location ?? '');

    if (uri.pathSegments.isEmpty) {
      return SynchronousFuture(
        PagesConfiguration(pagesStack: initialStackBuilder()),
      );
    }

    final stack = _parsePathSegments(uri.pathSegments, routes, page404);

    if (stack.pageNodesStack.isEmpty ||
        stack.activeStackFlattened().any((e) => e == page404)) {
      return SynchronousFuture(
        PagesConfiguration(
          pagesStack: NavigationStack([AppPageNode(page: page404)]),
        ),
      );
    }

    return SynchronousFuture(
      PagesConfiguration(pagesStack: stack),
    );
  }

  @override
  RouteInformation restoreRouteInformation(PagesConfiguration configuration) {
    final res = configuration.appPagesStack
        .map((e) => e.getPagePath())
        .join('/')
        .replaceAll(RegExp(r'\/+'), '/');
    return RouteInformation(
      location: res.isNotEmpty && res[0] != '/' ? '/$res' : res,
    );
  }
}
