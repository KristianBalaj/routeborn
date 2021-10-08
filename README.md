<p align="center">  
  <img src="https://raw.githubusercontent.com/KristianBalaj/routeborn/main/resources/logo.png" height="180" alt="Routeborn logo"></img>
</p>

<p align="center">
  <a href="https://github.com/KristianBalaj/routeborn/actions/workflows/build.yml"><img src="https://github.com/KristianBalaj/routeborn/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://img.shields.io/badge/License-MIT-green"><img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License"></a>
  <a href="https://pub.dev/packages/routeborn"><img src="https://img.shields.io/pub/v/routeborn?color=blue" alt="pub version"></a>
  <a href="https://codecov.io/gh/KristianBalaj/routeborn"><img src="https://codecov.io/gh/KristianBalaj/routeborn/branch/main/graph/badge.svg?token=JG4ZV64V0I"/></a>
</p>


<p align="center">  
<a href="https://www.buymeacoffee.com/kristianbalaj" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>  
</p>  

---

**!!! The routeborn package is still in active development and more frequent API changes are a possibility in a future until it reaches a stable version !!!**

- [Introduction](#introduction)
- [Usage](#usage)
- [Capabilities](#capabilities)
- [What the package cannot do?](#what-the-package-cannot-do)
- [Example use case](#example-use-case)
  - [Nested navigation](#nested-navigation)
    - [Preserving stacks](#preserving-stacks)
- [TODOs](#todos)
- [FAQ](#faq)
  - [Can I use multiple Routers for branching, having one Router per branch?](#can-i-use-multiple-routers-for-branching-having-one-router-per-branch)
  - [How to customize page transitions?](#how-to-customize-page-transitions)
- [Support](#support)

## Introduction
Flutter crossplatform routing based on Navigator 2.0. Capable of handling nested navigation with ease. 
The solution is based on the Flutter's widgets `MaterialApp.router`, `Router` and `Navigator`.

## Usage

Decide on the location of `Router` widgets in your app (Basic usage is by using the `MaterialApp.router` constructor as the initial App widget, e.g. a `MaterialApp` that uses a `Router` internally). 
Other places should use the `Router` directly.
Use the `RoutebornNestedRouterDelegate` and `RoutebornRootRouterDelegate`. 

Next, define `RoutebornPage` classes in your app based on your app logic. 
Each page needs to have `RoutebornPage`. 
The example project shows how to create such page, e.g. check out the [favorites_page.dart](https://github.com/KristianBalaj/routeborn/blob/main/example/lib/src/favorites_page.dart) file. 
There you can see class `FavoritesPage` that is extending the `RoutebornPage`. 
The other class is the `FavoritesPageView` that is a `StatelessWidget` just like you know it.

Last but not least, define routes of your app. 
The routes can be defined ideally in a separate file called `routes.dart` (e.g. [routes.dart in the example project](https://github.com/KristianBalaj/routeborn/blob/main/example/lib/src/routes.dart)). 

Finally, create a `NavigationNotifier` somewhere in your app in a way where the `NavigationNotifier` will be persisted during the App's lifetime.
After that use the `NavigationNotifier` to navigate through your app.

**NOTICE 1:** The `NavigationNotifier` needs to be persisted during the lifetime of your App since it takes care of all your navigation stacks. 
This can be achieved either by placing it inside a `StatefulWidget` at the root of your widgets tree, inside an `InheritedWidget` or make it persistent and accessible by using any state management mechanism of your liking (the example project uses the riverpod package and places the `NavigationNotifier` inside a `Provider`).

**Notice 2:** The router delegates could be preserved in memory during the lifetime of widgets that use them (widgets that are embedding the `Router` widget).
This is not necessary, but there is no need for them to rebuild every time.
You should place them in an `InheritedWidget`, `StatefulWidget` or in any other state management mechanism of your choice (e.g. inside a `Provider` when using Riverpod state management, etc.).
The `RoutebornRootRouterDelegate` should be in the memory during the lifetime of the app. 
On the other hand, the `RoutebornNestedRouterDelegate` will be created and destroyed based on the pages in the stacks.

## Capabilities

- Accessing navigation with or without the `BuildContext`
- No need for a `build_runner` that slows down your CI/CD
- Basic control to the navigation stack
  - `pushPage`, `popPage`, `popUntil`, `replaceAllWith`, `replaceLastWith`, `replaceRootStackWith` and `setNestingBranch` used for the nested navigation
  - Also, getting the state of navigation stack: `canPop`, `isLastPage<T>`, `containsPage<T>`, `getNavigationStack` and specifically for the nested navigation the `getNestingBranch`
- Nested navigation
  - Controlling parent or __even the child navigation stack__ using the `BuildContext` (__BOOM: game-changer__, this is actually a nice simplification, where you don't need to pass `Key`s to children to access them)
  - Endless nesting (However, I can't imagine higher level of nesting than 3 :) )
- Deep linking out of the box
  - Dialogs, Drawers and other types of routes can modify the URL, too
  - Path parameters
  - COMMING SOON: Query parameters
  - COMING SOON: Updating URL without changing the navigation stack (Hashtag style navigation, e.g. "myurl/blog#intoduction")
- Static declaration of routes
- Auto-filling of stacks (e.g When pushing a page with nested navigation, all the nested branches are autofilled by defaults and don't need to be defined on pushing)
- Either single or multilple `Router`s for the nested navigation (in the case of multiple `Router`s, the number of them is dependent on the nested branches count)
- COMING SOON: Customizing system back button handling
- COMING SOON: Returning a parameter from a popped page on page pop to the caller

## What the package cannot do?

This is a list of features that probably won't be supported in near future.

- Each page has to contain some constant path token
  
  **Example:**

  Take an imaginary `ProductPage` as an example: This page can be parametrized and cannot have the URL path only dynamic. It has to contain some constant part, too. 
  The path parameter `some-product-id` could be some hash corresponding to a Product that is on the `ProductPage`.
  
  *Possible page URL:* `..../product-detail/some-product-id`

  *URL that cannot be used for the page:* `..../some-product-id`

- Infinite URLs are not supported
  
  You cannot have an URL such as `..../foo/bar/foo/bar/foo/bar/....` going on forever. 
  You define all your paths in the `routes.dart` file and these are static. 
  You can go only as deep as you define in the `routes.dart`.

- Routes cannot to be non-deterministic
  
  **Example:**

  Having a simplified navigation tree as following:

  ```
  ── HomePage
      ├─ Branch: Shop
      │   └─ ProductPage
      └─ Branch: Favorites
          └─ ProductPage
  ```

  The problem here is that when navigating via a URL navigating to a Shop branch will have a URL of:
  
  `..../home/product-detail/product-id`

  But when navigating via URL to a Favorites branch, it also has URL of:

  `..../home/product-detail/product-id`

  These are the same and the package cannot determine which branch to open when navigating via URL since they contain the same pages.

  **Solution:**
  A possible solution is to create a separate `RoutebornPage` for shop's `ProductPage` and favorite's `ProductPage`.
  These pages will have a different URL page path (e.g. `shop-product-detail` and `favorites-product-detail`).


## Example use case

In the following tree structure, we can see one of possible states of navigation.
This example is for an imaginary E-shop app that can be seen in [an example app](https://github.com/KristianBalaj/routeborn/tree/main/example), too.

There are 3 pages in the root stack. **LoginPage**, **HomePage** and **HelpPage**. As we can see the **LoginPage** and **HelpPage** are basic pages with no nested navigation.

### Nested navigation
On the other hand, the **HomePage** is a page that utilizes the nested navigation. 
Nested navigation is specific by the branching. 
A nested Navigator can be branching, each branch having its own stack of pages. 
These stacks are persisted when switching branches.

The **HomePage** in the example below is covered by the **HelpPage** which could be a simple page with some additional information for customers. When the **HelpPage** in the root stack is popped, the **HomePage** becomes visible.

An example of the **HomePage** page could be a widget having a bottom bar navigation with tabs corresponding to the branches of the nested navigation. These tabs would be **Shop**, **Favorites** and **Cart** respectively to the navigation tree in the example below.

#### Preserving stacks

As we can see in the navigation tree below, all the branches have their navigation stacks preserved. Meaning, when a tab is switched from **Shop** to **Favorites** and back, the stack of the **Shop** branch is preserved. In our example, a detail page of a product is still opened. After tapping on a back button in the UI, the **ProductDetailPage** can be popped and the only page remaining the navigation stack of the **Shop** branch is the **ShopPage**.

<!-- https://www.compart.com/en/unicode/block/U+2500 -->
```
┌─ LoginPage
├─ HomePage
│   ├─ Branch: Shop
│   │   ├─ ShopPage
│   │   └─ ProductDetailPage
│   ├─ Branch: Favorites
│   │   ├─ FavoritesPage
│   │   └─ ProductDetailPage
│   └─ Branch: Cart
│       └─ CartPage
└─ HelpPage
```


## TODOs

You can file a new feature request as a Github issue or to change priority of this list.

- [ ] Add examples
- [ ] Upgrade documentation
  - [ ] Add FAQ
- [ ] Wrapper object for routes
- [ ] Drop 3rd party packages use
- [ ] Prepare a dialog page, that could control the URL, too. (it is actually possible to do with the API, but this should be build-in)
- [ ] Test coverage
  - [ ] cover with tests where multiple navigators are used for a crossroad
  - [ ] validate navigator keys to be the same on changing nested stack in nested router delegate
- [ ] Page transitions control
- [ ] Query parameters
- [ ] Customizing system back button handling
- [ ] Passing an argument back to the caller when popping a page. (How should this be solved when for example replacing a whole stack? There is no caller then.)
- [ ] Updating URL without changing the navigation stack (Hashtag style navigation, e.g. "myurl/blog#intoduction")
- [ ] Navigation listeners (could be used for logging current stacks)
- [ ] Dynamic page names
  - [ ] Based on content of widgets (e.g set page name after network response)
- [ ] Optimize traversing the navigation stacks (currently traversing by DFS from the start. Should traverse from the end, what makes more sense, since the navigation is mostly changing from the end branches) - this is reasonable only for apps with huge navigation stacks

## FAQ

### Can I use multiple Routers for branching, having one Router per branch?

This is necessary for example when using the `CupertinoTabScaffold` from the Flutter framework. 
There is a separate builder for each tab. Each Tab needs to have a separate `Router`. 

Each of these `Router`s will be having a `RoutebornNestedRouterDelegate` as a router delegate.
Each `RoutebornNestedRouterDelegate` needs to have passed a branch as an argument corresponding to the tab's branch.

An example of usage of the `CupertinoTabScaffold` can be seen in our example in the [home_page.dart](https://github.com/KristianBalaj/routeborn/blob/main/example/lib/src/home_page.dart).

When it is enough for you to have a single Router to handle all the branches, then you don't need to pass the branch parameter to the `RoutebornNestedRouterDelegate`.

### How to customize page transitions?

All the `RoutebornPage`s use the `MaterialPageRoute` by default in the `createRoute` method.

Thanks to this, transitions for all the pages can be customized using the `pageTransitionsTheme` in the `Theme`.

**Example:**
```dart

MaterialApp(
  theme: ThemeData(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      )
  )
)

```

To customize a single page, you can override the `createRoute` method in the `RoutebornPage` to return a Route of your liking where you can customize transitions.


## Support

You can create [an issue on **Github**](https://github.com/KristianBalaj/routeborn/issues) or to create a PR when you've found a bug or in case of a feature request.

I will be glad when you [support me via **Buy Me A Coffee**](https://www.buymeacoffee.com/kristianbalaj).

<a href="https://www.buymeacoffee.com/kristianbalaj" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>  