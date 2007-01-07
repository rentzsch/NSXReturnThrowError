/***************************************************************************//**
	NSXReturnThrowError.h
		Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://opensource.org/licenses/mit-license.php>

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
