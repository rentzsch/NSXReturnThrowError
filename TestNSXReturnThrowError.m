#import <Foundation/Foundation.h>
#import "NSXReturnThrowError.m"
#include <mach/error.h>

//--

static OSErr returnNoOSErr() { return 0; }
static OSStatus returnNoOSStatus() { return 0; }
static int returnNoPosixErr() { return 0; }
static mach_error_t returnNoMach_error() { return err_none; }
static id returnObjCInstance() { return [NSFileManager defaultManager]; }
static char* returnGoodCharPtr(){ return "foo"; }
static int* returnGoodIntPtr(){ static int dummy = 42; return &dummy; }
static BOOL returnGoodBool(){ return YES; }
static BOOL returnGoodBoolAndNoError(NSError **error) { return YES; }

static OSErr returnOSErr() { return qErr; }
static OSStatus returnOSStatus() { return qErr; }
static int returnPosixErr() { errno = EPERM; return -1; }
static mach_error_t returnMach_error() { return err_local|1; }
static id returnNilObjCInstance() { return nil; }
static char* returnBadCharPtr(){ return NULL; }
static int* returnBadIntPtr(){ return NULL; }
static BOOL returnBadBool(){ return NO; }
static BOOL returnBadBoolAndError(NSError **error) { assert(error); *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil]; return NO; }

//--

int main (int argc, const char * argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	//--
	
	#define errorCodeTypeFromRValue(RVALUE)	NSXErrorCodeTypeFromObjCType(@encode(typeof(RVALUE)))
	assert(NSXErrorCodeType_Carbon == errorCodeTypeFromRValue(returnNoOSErr()));
	assert(NSXErrorCodeType_Carbon == errorCodeTypeFromRValue(returnNoOSStatus()));
	assert(NSXErrorCodeType_PosixOrMach == errorCodeTypeFromRValue(returnNoPosixErr()));
	assert(NSXErrorCodeType_PosixOrMach == errorCodeTypeFromRValue(returnNoMach_error()));
	assert(NSXErrorCodeType_Cocoa == errorCodeTypeFromRValue(returnObjCInstance()));
	
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
	NSXReturnError(returnGoodCharPtr());
		assert(!error);
	NSXReturnError(returnGoodIntPtr());
		assert(!error);
	NSXReturnError(returnGoodBool());
		assert(!error);
	NSXReturnError(returnGoodBoolAndNoError(&error));
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
	NSXReturnError(returnBadCharPtr());
		assert(error);
		assert([[error domain] isEqualToString:NULLPointerErrorDomain]);
		assert([error code] == -1);
		error = nil;
	NSXReturnError(returnBadIntPtr());
		assert(error);
		assert([[error domain] isEqualToString:NULLPointerErrorDomain]);
		assert([error code] == -1);
		error = nil;
	NSXReturnError(returnBadBool());
		assert(error);
		assert([[error domain] isEqualToString:BOOLErrorDomain]);
		assert([error code] == -1);
		error = nil;
	NSXReturnError(returnBadBoolAndError(&error));
        assert(error);
        assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
        assert([error code] == paramErr);
        error = nil;
	
	//--
	
	NS_DURING
		NSXThrowError(returnOSErr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSXError"]);
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
		assert([[localException name] isEqualToString:@"NSXError"]);
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
		assert([[localException name] isEqualToString:@"NSXError"]);
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
		assert([[localException name] isEqualToString:@"NSXError"]);
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
		assert([[localException name] isEqualToString:@"NSXError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSCocoaErrorDomain]);
		assert([error code] == -1);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnBadCharPtr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSXError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NULLPointerErrorDomain]);
		assert([error code] == -1);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnBadIntPtr());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSXError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NULLPointerErrorDomain]);
		assert([error code] == -1);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnBadBool());
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSXError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:BOOLErrorDomain]);
		assert([error code] == -1);
		error = nil;
	
	NS_DURING
		NSXThrowError(returnBadBoolAndError(&error));
		assert(0);
	NS_HANDLER
		assert([[localException name] isEqualToString:@"NSXError"]);
		error = [[localException userInfo] objectForKey:@"error"];
	NS_ENDHANDLER
		assert(error);
		assert([[error domain] isEqualToString:NSOSStatusErrorDomain]);
		assert([error code] == paramErr);
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
