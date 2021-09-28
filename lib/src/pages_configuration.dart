import 'package:routeborn/src/navigation_notifier.dart';
import 'package:routeborn/src/routeborn_page.dart';

class PagesConfiguration<T> {
  final NavigationStack<T> pagesStack;

  List<RoutebornPage> get appPagesStack =>
      pagesStack.activeStackFlattened().toList();

  PagesConfiguration({
    required this.pagesStack,
  });

  @override
  String toString() {
    return pagesStack.toString();
  }
}
