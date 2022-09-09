## Example tests are broken

Need to cancel timer. Maybe bring timer back instead of stream.

## Add "inherited" to View. Maybe move "registered" there, too, to be consistent with Registrar

So,

    class MyWidget extends View<MyWidgetViewModel> {
        MyWidget({super.key}) : super(inherited: true, viewModelBuilder: () => MyWidgetViewModel());
    }

To implement, edit Registrar to add a mixin for handling registering and inheriting and add the
mixin to the View class.