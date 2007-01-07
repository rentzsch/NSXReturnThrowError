#import <Foundation/Foundation.h>
#import <NSXReturnThrowError.h>
#include <mach/error.h>

#ifndef ERRSTR_T
	#define ERRSTR_T
	typedef	const char*	errstr_t;
#endif

//--

static OSErr returnNoOSErr() { return 0; }
static OSStatus returnNoOSStatus() { return 0; }
static int returnNoPosixErr() { return 0; }
static mach_error_t returnNoMach_error() { return err_none; }
static id returnObjCInstance() { return [NSFileManager defaultManager]; }
static errstr_t returnNoErrstr() { return NULL; }

static OSErr returnOSErr() { return qErr; }
static OSStatus returnOSStatus() { return qErr; }
static int returnPosixErr() { errno = EPERM; return -1; }
static mach_error_t returnMach_error() { return err_local|1; }
static id returnNilObjCInstance() { return nil; }
static errstr_t returnErrstr() { return "some_error"; }

//--

int main (int argc, const char * argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	//--
	
	#define errorCodeTypeFromRValue(RVALUE)	errorCodeTypeFromObjCType(@encode(typeof(RVALUE)))
	assert(JRErrorCodeType_Carbon == errorCodeTypeFromRValue(returnNoOSErr()));
	assert(JRErrorCodeType_Carbon == errorCodeTypeFromRValue(returnNoOSStatus()));
	assert(JRErrorCodeType_PosixOrMach == errorCodeTypeFromRValue(returnNoPosixErr()));
	assert(JRErrorCodeType_PosixOrMach == errorCodeTypeFromRValue(returnNoMach_error()));
	assert(JRErrorCodeType_Cocoa == errorCodeTypeFromRValue(returnObjCInstance()));
	assert(JRErrorCodeType_errstr == errorCodeTypeFromRValue(returnNoErrstr()));
	
	//--
	
	NSXReturnError(returnNoOSErr());
		assert(!error);
	NSXReturnError(returnNoOSStatus());
		assert(!error);
	NSXReturnError(returnNoPosixErr());
		assert(!error);
	NSXReturnError(returnNoMach_error());
		assert(!error);
	NSXReturnError(returnObjCInstance());
		assert(!error);
	NSXReturnError(returnNoErrstr());
		assert(!error);
	
	//--
	
	NSXReturnError(returnOSErr());
		assert(error);
		assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
		assert([error code] == qErr);
		error = nil;
	NSXReturnError(returnOSStatus());
		assert(error);
		assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
		assert([error code] == qErr);
		error = nil;
	NSXReturnError(returnPosixErr());
		assert(error);
		assert([[error domain] isEqualToString:NSPOSIXErrorDomain]);
		assert([error code] == EPERM);
		error = nil;
	NSXReturnError(returnMach_error());
		assert(error);
		assert([[error domain] isEqualToString:NSMachErrorDomain]);
		assert([error code] == (err_local|1));
		error = nil;
	NSXReturnError(returnNilObjCInstance());
		assert(error);
		assert([[error domain] isEqualToString:NSCocoaErrorDomain]);
		assert([error code] == -1);
		error = nil;
	NSXReturnError(returnErrstr());
		assert(error);
		assert([[error domain] isEqualToString:@"errstr"]);
		assert([error code] == -1);
		assert([[[error userInfo] objectForKey:@"errstr"] isEqualToString:@"some_error"]);
		error = nil;
	
	//--
	
	NS_DURING
		NSXThrowError(returnOSErr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
		assert([error code] == qErr);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnOSStatus());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
		assert([error code] == qErr);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnPosixErr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSPOSIXErrorDomain]);
		assert([error code] == EPERM);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnMach_error());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSMachErrorDomain]);
		assert([error code] == (err_local|1));
		error = nil;
	
	NS_DURING
		NSXThrowError(returnNilObjCInstance());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSCocoaErrorDomain]);
		assert([error code] == -1);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnErrstr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:@"errstr"]);
		assert([error code] == -1);
		assert([[[error userInfo] objectForKey:@"errstr"] isEqualToString:@"some_error"]);
		error = nil;
	
	//--
		
	NSXReturnError(open("/does/not/exist", O_RDONLY, 0));
		assert(error);
		assert([[error domain] isEqualToString:NSPOSIXErrorDomain]);
		assert([error code] == ENOENT);
		error = nil;
	
	[pool release];
	printf("success\n");
	return 0;
}
