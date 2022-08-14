## Listen to Properties

Add Properties and ability to listen to them. An approach is to add the ability to register 
properties (same as models), but this led to a confusing API. So, maybe limit registering to Models 
and add functionality to retrieve Properties from registered Models.

So, introduce 

    Property<U> listenToProperty<T, U>({String? modelName, String? propertyName);

For consistency, rename 

    T listenTo<T>({String? name});

to

    T listenToModel<T>({String? name});

Ditto for 'get'. So, usage would look like:

    @override
    Widget build(BuildContext context) {
      final user = listenToProperty<Cloud, User>().value;
         :
      final user = getProperty<Cloud, User>().value;
         :

and

    @override
    Widget build(BuildContext context) {
      final user = listenToProperty<Cloud, User>(modelName: 'AWS', propertyName: 'currentUser').value;
         :
      final user = getProperty<Cloud, User>(modelName: 'AWS', propertyName: 'currentUser').value;
         :

and

    @override
    Widget build(BuildContext context) {
      final cloud = listenToModel<Cloud>(name: 'AWS');
         :
      final cloud = getModel<Cloud>(name: 'AWS');
         :

and 

    class Cloud extends Model {
      late final currentUser = buildProperty<User>(null, name: 'currentUser');

      void setUser(User user) {
        currentUser.value = user;
      }
     
would need to add check for property in Model 

    bool hasProperty<T>({String? name});

that Model.get(listenTo)Property would then use to give intelligent error messages. E.g.,

    '''getProperty failed because Model<MyModel>(name: null) has not added Property<User>(name: null).
    Here is a list properties added to this Model:
       (list properties or say there are none.)
    Missing Properties can be caused by using 'late' and not assigning the Property a value before 
    trying to reference it. E.g., the code below will likewise fail if getProperty is called before 
    setUser.

      late final currentUser = buildProperty<User>(null, name: 'currentUser');
      void setUser(User user) {
        currentUser.value = user;
      }

    You can use the Model.hasProperty member function to check if the for the above conditon.'''

To listen to Properties of non-registered Models:

    final user = listenToProperty(modelInstance: myModel, propertyName: 'currentUser').value;

And to listen to a non-registered Model:

    final user = listenToModel<Cloud>(instance: model).currentUser.value;

## Add registry output for debugging

    When a registry lookup fails, it would be handy to dump the closest matches. E.g.,
    With same type or with different type but same name.

## Add Property

**Status: Done v0.4.0**

Consider extending ValueNotifier to "Property" to facilitate adding listeners and registering. E.g.,

    class MyViewModel extends ViewModel {
      final counter = Property<int>(0, register: true, name: 'MyViewModel.counter');
      // or if remove register:true requirement when naming
      final counter = Property<int>(0, name: 'MyViewModel.counter');
      final someNotifier = Property<SomeNotifier>(SomeNotifier());
      @override
      void initState() {
        super.initState();

        // manually add listeners
        counter.addListener(buildView);
        someNotifier.addListener(notifyListeners);

        // or batch add like this...
        addListeners([
          {counter, buildView},
          {someNotifier, notifyListeners},
          {anotherNotifier, customListener},
        ]);
      }
    }

## For brevity, consider removing requirement to set 'register' true when 'name' != null;

**Status: Done v0.4.0**