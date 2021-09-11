import 'package:routeborn/src/app_page.dart';
import 'package:routeborn/src/navigation_notifier.dart';

class PagesConfiguration<T> {
  final NavigationStack<T> pagesStack;

  List<AppPage> get appPagesStack => pagesStack.activeStackFlattened().toList();

  PagesConfiguration({
    required this.pagesStack,
  });

  @override
  String toString() {
    return pagesStack.toString();
  }
}
