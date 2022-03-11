# 0.4.1
- **feat:** specifying route transitions per platform

# 0.4.0
- **feat:** nesting branch can now be parametrized via `RoutebornBranchParams`

# 0.3.7
- **feat:** export `SetPageNameCallback`

# 0.3.6
- **feat:** export `UpdatablePageNameMixin`

# 0.3.5
- **feat:** added `UpdatablePageNameMixin`

# 0.3.4
- **refactor:** remove unnecessary field in `RoutebornPage`

# 0.3.3
- **fix:** `popUntil` was not calling notifyListeners

# 0.3.2
- **feat:** `getNavigationStack` method implemented.

# 0.3.1
- **feat:** `pushPage`, `popPage`, `replaceLastWith`, `replaceAllWith` and `popUntil` now working even without a Navigator in the context (when called before an initial `Router`). The fallback `Router` on calling such methods will be the root `Router`.
- **docs:** updating documentation's robustness 

# 0.3.0
- **feat:** adding simple example app using routeborn
- **feat:** adding initial documentation
- **feat:** `RoutebornPage` now uses `MaterialPageRoute` as a default route, making it possible to customize transitions via Theme
- **fix:** page animations in nested routes when using multiple navigators 
- **BREAKING:** changing `AppPage` to `RoutebornPage`

# 0.2.6

- **feat:** added option `inChildNavigator` to `replaceAllWith` method
- **BREAKING:** renamed `getCurrentNestingBranch` to `getNestingBranch`
- **BREAKING:** renamed `setCurrentNestingBranch` to `setNestingBranch`

# 0.2.5

- **feat:** added `popUntil` method

# 0.2.4

- **feat:** `setNestingBranch` has now option to reset the stack of the given branch

# 0.2.3

- **fix:** setting new route path

# 0.2.2

- **fix:** package exports

# 0.2.1

- **fix:** package exports

# 0.2.0

- configurability of branches
- fixes of navigation notifier methods when called from nested branch with multi-navigators

# 0.1.0

Initial release

# 0.0.1

Package setup
