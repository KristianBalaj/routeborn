import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/navigation_notifier.dart';

Matcher appPageNodesStackEquals<T>(List<TestNode<T>> nodes) =>
    _AppPageNodesMatcher<T>(nodes);

class _AppPageNodesMatcher<T> extends CustomMatcher {
  _AppPageNodesMatcher(List<TestNode<T>> nodes)
      : super(
          'nodes stacks',
          'nodes stacks',
          pairwiseCompare<TestNode<T>, AppPageNode<T>>(
              nodes, _equals, 'given node'),
        );

  static bool _equals<T>(TestNode<T> testNode, AppPageNode<T> realNode) {
    if (testNode.pageType != realNode.page.runtimeType) return false;
    if (testNode.crossroad == null) {
      return realNode.crossroad == null;
    }
    if (realNode.crossroad == null) return false;

    if (!setEquals(
      Set.of(testNode.crossroad!.availableBranches.keys),
      Set.of(realNode.crossroad!.availableBranches.keys),
    )) return false;

    if (testNode.crossroad!.availableBranches.length !=
        realNode.crossroad!.availableBranches.length) {
      return false;
    }

    final zippedBranchEntries = testNode.crossroad!.availableBranches.entries
        .map((e) => Tuple2(
            e.value,
            realNode.crossroad!.availableBranches.entries
                .firstWhere((other) => other.key == e.key)))
        .toList();

    return testNode.crossroad!.activeBranch ==
            realNode.crossroad!.activeBranch &&
        zippedBranchEntries.every(
          (a) =>
              a.value1.length == a.value2.value.pageNodesStack.length &&
              IList.from(a.value2.value.pageNodesStack)
                  .zip(IList.from(a.value1))
                  .every((a) => _equals(a.value2, a.value1)),
        );
  }

  @override
  Object featureValueOf(covariant NavigationStack<T> actual) {
    return actual.pageNodesStack;
  }
}

class TestCrossroad<T> {
  final T activeBranch;
  final Map<T, List<TestNode<T>>> availableBranches;

  TestCrossroad(this.activeBranch, this.availableBranches);

  @override
  String toString() {
    return '{- active: $activeBranch, availableBranches: $availableBranches -}';
  }
}

class TestNode<T> {
  final Type pageType;
  final TestCrossroad<T>? crossroad;

  TestNode(this.pageType, this.crossroad);

  @override
  String toString() {
    return '(- $pageType, crossroad: $crossroad -)';
  }
}
