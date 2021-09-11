import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routeborn/src/navigation_notifier.dart';

Matcher appPageNodesStackEquals(List<TestNode> nodes) =>
    _AppPageNodesMatcher(nodes);

class _AppPageNodesMatcher extends CustomMatcher {
  _AppPageNodesMatcher(List<TestNode> nodes)
      : super(
          'nodes stacks',
          'nodes stacks',
          pairwiseCompare<TestNode, AppPageNode>(nodes, _equals, 'given node'),
        );

  static bool _equals(TestNode testNode, AppPageNode realNode) {
    if (testNode.pageType != realNode.page.runtimeType) return false;
    if (testNode.crossroad == null) {
      return realNode.crossroad == null;
    }
    if (realNode.crossroad == null) return false;

    int nestingBranchComparer(NestingBranch a, NestingBranch b) {
      return a.index.compareTo(b.index);
    }

    if (!setEquals(
      Set.of(testNode.crossroad!.availableBranches.keys),
      Set.of(realNode.crossroad!.availableBranches.keys),
    )) return false;

    if (testNode.crossroad!.availableBranches.length !=
        realNode.crossroad!.availableBranches.length) {
      return false;
    }

    final zippedBranchEntries = IList.from(
      testNode.crossroad!.availableBranches.entries.toList()
        ..sort((a, b) => nestingBranchComparer(a.key, b.key)),
    ).zip(
      IList.from(
        realNode.crossroad!.availableBranches.entries.toList()
          ..sort((a, b) => nestingBranchComparer(a.key, b.key)),
      ),
    );

    return testNode.crossroad!.activeBranch ==
            realNode.crossroad!.activeBranch &&
        zippedBranchEntries.every(
          (a) =>
              a.value1.value.length == a.value2.value.pageNodesStack.length &&
              IList.from(a.value2.value.pageNodesStack)
                  .zip(IList.from(a.value1.value))
                  .every((a) => _equals(a.value2, a.value1)),
        );
  }

  @override
  Object featureValueOf(covariant NavigationStack actual) {
    return actual.pageNodesStack;
  }
}

class TestCrossroad {
  final NestingBranch activeBranch;
  final Map<NestingBranch, List<TestNode>> availableBranches;

  TestCrossroad(this.activeBranch, this.availableBranches);

  @override
  String toString() {
    return '{- active: $activeBranch, availableBranches: $availableBranches -}';
  }
}

class TestNode {
  final Type pageType;
  final TestCrossroad? crossroad;

  TestNode(this.pageType, this.crossroad);

  @override
  String toString() {
    return '(- $pageType, crossroad: $crossroad -)';
  }
}
