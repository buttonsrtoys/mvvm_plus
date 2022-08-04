# Example
(The source code for the package example is under the Pub.dev "Example" tab and in the GitHub `example/lib/main.dart` file.)

This example increments a number (0, 1, 2, ...) and a letter character (a, b, c, ...) using a single
increment floating action button (FAB) that toggles between incrementing the number and the 
letter. When the FAB displays "+1" a press increments the number and when it displays "+a" the 
character will increment. 

Two View widgets are used in this example. One for the increment button/FAB which maintains the
state ("+1"/"+a") and one for the page which maintains current count and other states.

The page listens to two services: one that changes the number color and another that changes the 
letter color. The number color service has a stream that emits a new color every N seconds. The 
letter color service is a ChangeNotifier with a timer that changes the current letter color and 
then calls `notifyListeners`.

<img src="https://github.com/buttonsrtoys/view/blob/main/example/example.gif" width="400"/>