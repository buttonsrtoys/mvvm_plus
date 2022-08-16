## Add registry output for debugging

When a registry lookup fails, it would be handy to dump the closest matches. E.g., With same type or
with different type but same name.

This would be a change to Registrar.

## Optionally use context like Provider?

Optionally get or listenTo Models using context. I.e., add Provider to Registrar.

This would be a change to Registrar.

So, could

    final cloud = get<Cloud>();
    final user = listenTo<Cloud>(notifier: cloud.currentUser).value;

Or

    final cloud = get<Cloud>(context: context);
    final user = listenTo<Property<User>>(context: context, notifier: cloud.currentUser).value;

Registrar

    Registrar(
      builder: () => MyModel,
      register: false, // <- Does not add to registry, so need Provider to get
      child: Container(),
    }