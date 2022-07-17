# package view example

A twist on the common Flutter counter project. 

## Description

This example increments a number (0, 1, 2, ...) and a letter character (a, b, c, ...) using a single
increment floating action button (FAB) that toggles between incrementing the number and the 
letter. When the FAB displays "+1" a press increments the number and when it displays "+a" the 
character will increment. 

Two `View` widgets are used in this example. The increment button/FAB maintains a state ("+1"/"+a") 
so an `View` widget was used. The page maintains current count and other states, so an `View` widget 
was also used.

The page listens to two services: one that changes the number color and another that changes the 
letter color. The number color service has a stream that emits a new color every N seconds. The 
letter color service is a `ChangeNotifier` with a timer that changes the current letter color and 
then calls `notifyListeners`. The `ChangeNotifier` service was registered with 
`ChangeNotifierRegistrar`.

Note that registering the `ViewModel` of the `ColorPage` widget in this simple example was 
unnecessary as the Increment Button is a direct descendant, so the `ColorPage.viewWidget` reference 
is readily available. The `ViewModel` was registered to demo using `View.get` for situations when
registration would be required (e.g., when the retrieved `ViewModel` is on another branch of the 
widget tree.)

<img src="https://github.com/buttonsrtoys/get_mvvm/blob/main/example/example.gif" width="400"/>