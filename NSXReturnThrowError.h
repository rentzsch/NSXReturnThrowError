/***************************************************************************//**
	NSXReturnThrowError.h
		Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>
	
	@section Overview

		NSXReturnThrowError does two things:

		1. Eases wrapping error codes into NSError objects.

		2. Enhances NSError by adding origin information to the error instance.
		   Origin information includes the actual line of code that returned
		   the error, as well as the file+line+function/method name.

		A big NSXReturnThrowError feature is that it deduces the correct NSError
		error domain based on the wrapped code's return type+value. Bonus: it
		does so without requiring ObjC++, relying on \@encode acrobatics
		instead.

		NSXReturnThrowError was coded against 10.4, but should be compatibale
		with 10.3 as well. However that's currently untested.

	@section Usage

		NSXReturnThrowError handles both types of error handling: explicit
		returning of NSError objects and raising NSExceptions.

		Use NSXReturnError() if you're returning NSError objects explicitly:

		@code
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
		@endcode

		Use NSXThrowError() if you'd prefer to raise NSException objects:

		@code
		- (id)demo {
			id result = nil;
			
			NSXThrowError(SomeCarbonFunction());
			NSXThrowError(someposixfunction());
			NSXThrowError(some_mach_function());
			NSXThrowError([SomeCocoaClass newObject]);
			
			return result;
		}
		@endcode
		
		The current structure of the raised NSException object is that it's a
		normal NSException whose name is "NSError". The actual error object is
		hung off the exception's userInfo dictionary with the key of @"error".

	@mainpage	NSXReturnThrowError
	@bug		I bet this breaks on 10.5. Hopefully not beyond repair.
	@todo		Add a compile-time flag for whether to stuff __FILE__+friends
				info into the generated NSError or not.

	***************************************************************************/

#import <Foundation/Foundation.h>

typedef	enum {
	JRErrorCodeType_Unknown,
	JRErrorCodeType_Cocoa,			//	"@"
	JRErrorCodeType_PosixOrMach,	//	"i" (-1 == posix+errno, otherwise mach)
	JRErrorCodeType_Carbon,			//	"s" || "l"
	JRErrorCodeType_errstr			//	"r*" || "*"
}	JRErrorCodeType;

//--

#define	errorCodeTypeFromObjCType(objCType)														\
	({																							\
		JRErrorCodeType result;																	\
		switch (objCType[0]) {																	\
			case 's':																			\
			case 'l':																			\
				result = JRErrorCodeType_Carbon;												\
				break;																			\
			case 'i':																			\
				result = JRErrorCodeType_PosixOrMach;											\
				break;																			\
			case '@':																			\
				result = JRErrorCodeType_Cocoa;													\
				break;																			\
			case '*':																			\
				result = JRErrorCodeType_errstr;												\
				break;																			\
			case 'r':																			\
				result = '*' == objCType[1] ? JRErrorCodeType_errstr : JRErrorCodeType_Unknown;	\
				break;																			\
			default:																			\
				result = JRErrorCodeType_Unknown;												\
		}																						\
		result;																					\
	})

//--

#define	NSXReturnError(CODE)	\
	{	\
		typeof(CODE) codeResult = (CODE);	\
		if ('@' == @encode(typeof(codeResult))[0]) {	\
			if (nil == codeResult) {	\
				error = [NSError errorWithDomain:@"NSCocoaErrorDomain"	\
											code:-1	\
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
											[NSString stringWithUTF8String:__FILE__],   @"reportingFile",	\
											[NSNumber numberWithInt:__LINE__],   @"reportingLine",	\
											[NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",	\
											@#CODE, @"origin",	\
											nil]];	\
			}	\
		} else {	\
			if (0 != codeResult) {	\
				switch (errorCodeTypeFromObjCType(@encode(typeof(CODE)))) {	\
					case JRErrorCodeType_Carbon:	\
						error = [NSError errorWithDomain:NSOSStatusErrorDomain	\
													code:(int)codeResult	\
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
													[NSString stringWithUTF8String:__FILE__],   @"reportingFile",	\
													[NSNumber numberWithInt:__LINE__],   @"reportingLine",	\
													[NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",	\
													@#CODE, @"origin",	\
													nil]];	\
						break;	\
					case JRErrorCodeType_PosixOrMach:	\
						if (-1 == (int)codeResult) {	\
							error = [NSError errorWithDomain:NSPOSIXErrorDomain	\
														code:errno	\
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
														[NSString stringWithUTF8String:__FILE__],   @"reportingFile",	\
														[NSNumber numberWithInt:__LINE__],   @"reportingLine",	\
														[NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",	\
														@#CODE, @"origin",	\
														nil]];	\
						} else {	\
							error = [NSError errorWithDomain:NSMachErrorDomain	\
														code:(int)codeResult	\
													userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
														[NSString stringWithUTF8String:__FILE__],   @"reportingFile",	\
														[NSNumber numberWithInt:__LINE__],   @"reportingLine",	\
														[NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",	\
														@#CODE, @"origin",	\
														nil]];	\
						}	\
						break;	\
					case JRErrorCodeType_errstr:	\
						error = [NSError errorWithDomain:@"errstr"	\
													code:-1	\
												userInfo:[NSDictionary dictionaryWithObjectsAndKeys:	\
													[NSString stringWithUTF8String:__FILE__],   @"reportingFile",	\
													[NSNumber numberWithInt:__LINE__],   @"reportingLine",	\
													[NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",	\
													@#CODE, @"origin",	\
													[NSString stringWithUTF8String:(const char*)(intptr_t)codeResult], @"errstr",	\
													nil]];	\
						break;	\
					default:	\
						assert(0 && "unknown JRErrorCodeType");	\
						break;	\
				}	\
			}	\
		}	\
	}

#define NSXThrowError(CODE) \
	{	\
		NSError *error = nil;	\
		NSXReturnError(CODE);	\
		if (error) {	\
			[[NSException exceptionWithName:@"NSError"	\
									 reason:[error description]	\
								   userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]] raise];	\
		}	\
	}
