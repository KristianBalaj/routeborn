import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/routeborn_route_info_parser.dart';

class AppPageNodesStackUtil {
  AppPageNodesStackUtil._();

  /// Fills all the missing nested branches to defaults.
  /// Missing depending on the routes.
  static NavigationStack fillMissingNestedBranches(
    NavigationStack stack,
    Map<String, RouteNode> routes,
  ) {
    AppPageNode _fillMissing(
      AppPageNode pageNode,
      RouteNode routeNode,
    ) {
      if (routeNode.nestedBranches != null) {
        if (pageNode.crossroad == null) {
          return pageNode.copyWith(
            crossroad:
                NavigationCrossroad.fromBranches(routeNode.nestedBranches!),
          );
        } else {
          if (pageNode.crossroad!.availableBranches.keys
                  .toSet()
                  .union(routeNode.nestedBranches!.branches.keys.toSet())
                  .length >
              routeNode.nestedBranches!.branches.length) {
            throw NavigationStackError(
                'Routes don\'t match current nodes stack. '
                'Add the missing routes.');
          }

          return pageNode.copyWith(
            crossroad: pageNode.crossroad!.copyWith(
              availableBranches: routeNode.nestedBranches!.branches.map(
                (key, value) {
                  if (routeNode.nestedBranches!.branches[key] == null) {
                    throw NavigationStackError(
                        'Routes don\'t match current nodes stack. '
                        'Add the missing routes.');
                  }

                  if (pageNode.crossroad!.availableBranches[key] == null ||
                      pageNode.crossroad!.availableBranches[key]!.pageNodesStack
                          .isEmpty) {
                    return MapEntry(
                      key,
                      NavigationStack([
                        AppPageNode.fromBranchInitNode(
                            routeNode.nestedBranches!.branches[key]!)
                      ]),
                    );
                  } else {
                    final nodesStack = pageNode
                        .crossroad!.availableBranches[key]!.pageNodesStack;

                    return MapEntry(
                      key,
                      NavigationStack(
                        IList.from(nodesStack)
                            .mapWithIndex(
                              (i, e) => _fillMissing(
                                e,
                                _findRouteNodeByStack(
                                    {value.nodePathKey: value.node},
                                    nodesStack.take(i + 1).toList()),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (pageNode.crossroad == null) {
          return pageNode;
        } else {
          throw NavigationStackError('Routes don\'t match current nodes stack. '
              'Add the missing routes.');
        }
      }
    }

    return NavigationStack(
      IList.from(stack.pageNodesStack)
          .mapWithIndex(
            (i, e) => _fillMissing(
                e,
                _findRouteNodeByStack(
                    routes, stack.pageNodesStack.take(i + 1).toList())),
          )
          .toList(),
    );
  }

  static RouteNode _findRouteNodeByStack(
    Map<String, RouteNode> routes,
    List<AppPageNode> stack,
  ) {
    if (stack.isEmpty) {
      throw NavigationStackError('Empty stack has no route node.');
    }

    final node = routes[stack.first.page.getPagePathBase()];
    if (node == null) {
      throw NavigationStackError('Routes don\'t match current nodes stack. '
          'Add the missing routes.');
    }
    if (stack.length == 1) {
      return node;
    }
    return _findRouteNodeByStack(node.routes ?? {}, stack.skip(1).toList());
  }

  /// Finds a [NavigationCrossroad] by the [key]
  /// and updates it by the [onUpdateCrossroad] function.
  ///
  /// NOTICE: searches only through the active stacks recursively.
  static NavigationStack updateNestedStack(
    Key key,
    NavigationStack rootStack,
    NavigationCrossroad Function(NavigationCrossroad previousCrossroad)
        onUpdateCrossroad,
  ) {
    /// Creates a new instance of [NavigationStack] with replaced [NavigationCrossroad]
    /// belonging to the [navKey] in the stack.
    NavigationStack _replaceCrossroadByKey(
      NavigationCrossroad crossroad,
      Key navKey,
    ) {
      Iterable<AppPageNode> _internalReplace(
          List<AppPageNode> stackPages) sync* {
        for (var i = 0; i < stackPages.length; i++) {
          if (stackPages[i].crossroad == null) {
            yield stackPages[i];
          } else if (stackPages[i].crossroad!.navigatorKey == navKey) {
            yield stackPages[i].copyWith(crossroad: crossroad);
          } else {
            yield stackPages[i].copyWith(
              crossroad: stackPages[i].crossroad!.copyWithActiveBranchStack(
                    NavigationStack(
                      _internalReplace(
                        stackPages[i]
                            .crossroad!
                            .activeBranchStack
                            .pageNodesStack,
                      ).toList(),
                    ),
                  ),
            );
          }
        }
      }

      return NavigationStack(
          _internalReplace(rootStack.pageNodesStack).toList());
    }

    final crossroad = findCrossroadInActiveStackByKey(key, rootStack);

    assert(() {
      if (crossroad == null) {
        throw NavigationStackError(
            'Could not find crossroad with the given key in the active stack');
      }
      return true;
    }());

    return _replaceCrossroadByKey(
      onUpdateCrossroad(crossroad!),
      key,
    );
  }

  /// Looks only to the active branches
  static NavigationCrossroad? findCrossroadInActiveStackByKey(
    Key navKey,
    NavigationStack fromStack,
  ) {
    NavigationCrossroad? _internalFind(List<AppPageNode> stack) {
      for (var i = 0; i < stack.length; i++) {
        if (stack[i].crossroad == null) continue;

        if (stack[i].crossroad!.navigatorKey == navKey) {
          return stack[i].crossroad!;
        }

        return _internalFind(
            stack[i].crossroad!.activeBranchStack.pageNodesStack);
      }
    }

    return _internalFind(fromStack.pageNodesStack);
  }
}