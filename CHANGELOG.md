## 1.4.2
- Fixed link in ReadMe

## 1.4.1
- Reformatted code to 80 chars wide

## 1.4.0
- Upgraded bilocator to 1.6.0
- Cleanup of renaming of View to ViewModel and StatelessView to StatelessViewWidget

## 1.3.0
- Renamed View to ViewWidget because of a name collision on the Flutter beta channel.
- Renamed StatelessView to StatelessViewWidget to be consistent with ViewWidget renaming.
- Removed unused `equatable` dependency.

## 1.2.0
- Added FutureProperty and StreamProperty classes.
- Added Model.createFutureProperty() and Model.createStreamProperty() member functions.
- Added Model.createStreamProperty() and Model.createStreamProperty() member functions.
- Added check for whether View is mounted before calling setState.
- Refactored buildView to a name function.
- Renamed ViewWithStatelessViewModel to StatelessView.
- Improved example to show 10 counters.
- Added support for mixins for View class by exposing its underlying ViewState class.
  - Adds View.getState member function.
- Updated Readme documentation.

## 1.1.0
- Added ViewModel.buildViewCalls to facilitate unit testing of ViewModels.
- fixed bug where `name` was ignored in `ViewModel.listenTo(name: name)`.

## 1.0.6
Edited the readme page.

## 1.0.5
Fixed ending to short video.

## 1.0.4
Reworked example.
Added YouTube video to readme.

## 1.0.3
Updated readme with Medium article.

## 1.0.2
Fixed typo in readme.

## 1.0.1
Upgraded Bilocator.

## 1.0.0
- Added `createProperty` to ViewModel.
- Migrated to `bilocator` from `registrar`. (`bilocator` is `registrar` renamed).
- Changed parameter names to improve naming and to align `mvvm_plus` with the naming in `bilocator`.
- Breaking changes:
    - Changed Registrar class to Bilocator class.
    - Changed MultiRegistrar class to Bilocators.
    - Changed View parameter name `viewModelBuilder` to `builder`.
    - Moved ViewModel parameter `inherited` to View and change its name to `location`.
    - Moved ViewModel parameter `name` to View.

## 0.6.0
Upgraded Registrar, which now supports Registrar "location" parameter.

## 0.5.0
Upgraded Registrar, which now supports locating inherited models on the widget tree.

## 0.4.2
Updated readme.

## 0.4.1
Fixed format.

## 0.4.0
Added Model. Added "notifier" parameter to listenTo to support listening to ValueNotifiers.

## 0.3.1
Corrected changelog.

## 0.3.0
Added ViewWithStatelessViewModel, View.get, View.listenTo, and more tests.

## 0.2.4
Added widget tests. Made listenTo return type generic.

## 0.2.2
Fixed example gif.

## 0.2.1
Updated readme with example.

## 0.2.0
Added View member functions context, mounted, didUpdateWidget, reassemble, deactivate, activate, and
didChangeDependencies.

## 0.1.6
Updated description and readme.

## 0.1.5
Updated description to improve pub.dev search results.

## 0.1.4
Updated readme.

## 0.1.3
Fixed readme.

## 0.1.2
Change github visibility.

## 0.1.1
Updated pubspec.yam

## 0.1.0
Initial release.