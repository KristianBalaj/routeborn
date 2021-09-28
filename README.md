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

- [Introduction](#introduction)
- [Usage](#usage)
- [Capabilities](#capabilities)
- [Example use case](#example-use-case)
  - [Nested navigation](#nested-navigation)
    - [Preserving stacks](#preserving-stacks)
- [TODOs](#todos)
- [FAQ](#faq)

## Introduction
Flutter crossplatform routing based on Navigator 2.0. Capable of handling nested navigation with ease. 
The solution is based on the Flutter's widgets `MaterialApp.router`, `Router` and `Navigator`.

## Usage

Decide on the location of `Router` widgets in your app (Basic usage is by using the `MaterialApp.router` constructor as the initial App widget, e.g. a `MaterialApp` that uses a `Router` internally). 
Other places should use the `Router` directly.
Use the `RoutebornNestedRouterDelegate` and `RoutebornRootRouterDelegate`. 

Next, define `RoutebornPage` classes in your app based on your app logic. 
Last but not least, define routes of your app ideally in a separate file called `routes.dart`. Run your app and use the `NavigationNotifier` to control your App's navigation.

**NOTICE 1:** The router delegates should be preserved in memory during the lifetime of widgets that use them (widgets that are embedding the `Router` widget), so you should place them in a `InheritedWidget`, `StatefulWidget` or in any other state management mechanism of your choice (e.g. inside a `Provider` when using Riverpod state management, etc.).
The `RoutebornRootRouterDelegate` should be in the memory during the lifetime of the app. On the other hand, the `RoutebornNestedRouterDelegate` will be created and destroyed based on the pages in the stacks.

**NOTICE 2:** Also, the `NavigationNotifier` takes care of all your navigation stacks and should be preserved in memory during the lifetime of your app.



## Capabilities

- Accessing navigation with or without the `BuildContext`
- Basic control to the navigation stack
  - `pushPage`, `popPage`, `popUntil`, `replaceAllWith`, `replaceLastWith`, `replaceRootStackWith` and `setNestingBranch` used for the nested navigation
  - Also, getting the state of navigation stack: `canPop`, `isLastPage<T>`, `containsPage<T>` and for the nested navigation the `getNestingBranch`
- Nested navigation
  - Controlling parent or __even the child navigation stack__ (__BOOM: game-changer__) using the `BuildContext`
  - Endless nesting (However, I couldn't imagine higher level of nesting than 3 :) )
- Deep linking
  - Path parameters
  - COMMING SOON: Query parameters
  - COMING SOON: Updating URL without changing the navigation stack (Hashtag style navigation, e.g. "myurl/blog#intoduction")
- Static declaration of routes
- Auto-filling of stacks (e.g When pushing a page with nested navigation, all the nested branches are autofilled by defaults and don't need to be defined on pushing)
- Either single or multilple `Router`s for the nested navigation (in the case of multiple `Router`s, the number of them is dependent on the nested branches count)
- System back button handling

## Example use case

In the following tree structure, we can see one of possible states of navigation.
This example is for an imaginary E-shop app.

There are 3 pages in the root stack. **LoginPage**, **HomePage** and **HelpPage**. As we can see the **LoginPage** and **HelpPage** are basic pages with no nested navigation.

### Nested navigation
On the other hand, the **HomePage** is a page that utilizes the nested navigation. 
Nested navigation is specific by the branching. 
A nested Navigator can can be branching to separate branches each having its own stack of pages.

The **HomePage** in the example below is covered by the **HelpPage** which could be a simple page with some additional information for customers. When the **HelpPage** in the root stack is popped, the **HomePage** becomes visible.

An example of the **HomePage** page could be a widget having a bottom bar navigation with tabs corresponding to the branches of the nested navigation. These tabs would be **Shop**, **Favorites** and **Cart** respectively to the navigation tree in the example below.

#### Preserving stacks

As we can see in the navigation tree below, all the branches have their navigation stacks preserved. Meaning, when a tab is switched from **Shop** to **Favorites** and back, the stack of the **Shop** branch is preserved. In our example, a detail page of a product is still opened. After tapping on a back button in the UI, the **ProductDetailPage** can be popped and the only page remaining the navigation stack of the **Shop** branch is the **ShopPage**.

```
https://www.compart.com/en/unicode/block/U+2500
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
- [ ] Test coverage
  - [ ] cover with tests where multiple navigators are used for a crossroad
  - [ ] validate navigator keys to be the same on changing nested stack in nested router delegate
- [ ] Page transitions control
- [ ] Query parameters
- [ ] Updating URL without changing the navigation stack (Hashtag style navigation, e.g. "myurl/blog#intoduction")
- [ ] Navigation listeners (could be used for logging current stacks)
- [ ] Dynamic page names
  - [ ] Based on content of widgets (e.g set page name after network response)
- [ ] Optimize traversing the navigation stacks (currently traversing by DFS from the start. Should traverse from the end, what makes more sense, since the navigation is mostly changing from the end branches) - this is reasonable only for apps with huge navigation stacks

## FAQ