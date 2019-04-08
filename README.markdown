**NSXReturnThrowError** does two things:

1. Eases wrapping various kinds of error codes (Cocoa, Posix, Mach, Carbon) into `NSError` objects.

2. Enhances `NSError` by adding origin information to the error instance.  
Origin information includes the actual line of code that returned the error, as well as the file+line+function/method name.

A big **NSXReturnThrowError** feature is that it deduces the correct `NSError` error domain based on the wrapped code's return type+value. Bonus: it does so without requiring Objective-C++, relying on `@encode` acrobatics instead.

**NSXReturnThrowError** is compatible with Mac OS X 10.3-10.7 and every version of iOS.

### Usage

NSXReturnThrowError handles both types of error handling: explicit returning of `NSError` objects and raising `NSException`s.

Use `NSXReturnError()` if you're returning `NSError` objects explicitly:

```objc
- (id)demoReturnError:(NSError**)error_ {
	id result = nil;
	NSError *error = nil;
	
	NSXReturnError(SomeCarbonFunction());
	if (!error)
		NSXReturnError(someposixfunction());
	if (!error)
		NSXReturnError(some_mach_function());
	if (!error)
		NSXReturnError([SomeCocoaClass newObject]);
	
	if (error_) *error_ = error;
	return result;
}
```

Use NSXThrowError() if you'd prefer to raise NSException objects:

```objc
- (id)demo {
	id result = nil;

	NSXThrowError(SomeCarbonFunction());
	NSXThrowError(someposixfunction());
	NSXThrowError(some_mach_function());
	NSXThrowError([SomeCocoaClass newObject]);

	return result;
}
```

The current structure of the raised `NSException` object is that it's a normal `NSException` whose name is `"NSError"`. The actual error object is hung off the exception's `userInfo` dictionary with the key of `@"error"`. You can use code like this to report it:

```objc
if (error)
	NSLog(@"error:%@ userInfo:%@", error, [error userInfo]);
```

Or use [JRLog](https://github.com/rentzsch/JRLog)'s `JRLogNSError(error)`, which accomplishes the same thing.
