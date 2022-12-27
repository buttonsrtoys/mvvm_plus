# ViewModel needs mounted getter

# Add buildViewCalls
- Add a counter for `buildView` calls for testing.
- Fix test error when the late `buildView` not instantiated during test.
- Add tests

# Add Property class
- Has `valid` field.

# Get should be nullable
- E.g.,
  final myClass = get<MyClass?>();
  if (myClass != null) {..}

# Add explanations and alternatives to error messages
- 'Error: Tried to register an instance of type $T with name $name but it is already registered' 
could add. You have a couple options. Use the `name` parameter to make it unique or use the
`location` parameter to add the model to the tree (instead of the registry).

# Register BilocatorDelegates in construction
- Currently registered in Bilocators constructor. Register in BilocatorDelegate constructor.
- Is Bilocator registering in Constructor?

# Add comment regarding danger of passing closures to listenTo

# fix context.listenTo and .get to update on notifyListeners

# Rename Bilocators to MultiBilocators to be inline with Flutter?
