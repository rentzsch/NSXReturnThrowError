// NSXReturnThrowError.m semver:3.0.0
//   Copyright (c) 2007-2012 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/MIT
//   https://github.com/rentzsch/NSXReturnThrowError

#import "NSXReturnThrowError.h"

NSString *NSXErrorExceptionName = @"NSXError";
NSString *NULLPointerErrorDomain = @"NULLPointerErrorDomain";
NSString *BOOLErrorDomain = @"BOOLErrorDomain";
NSString *AssertionFailureErrorDomain = @"AssertionFailureErrorDomain";

typedef enum {
    NSXErrorCodeType_Unknown,
    NSXErrorCodeType_Cocoa,         //  "@"
    NSXErrorCodeType_PosixOrMach,   //  "i" (-1 == posix+errno, otherwise mach)
    NSXErrorCodeType_Carbon,        //  "s" || "l"
    NSXErrorCodeType_ptr,           //  "r*" || "*" || "^"
    NSXErrorCodeType_BOOL,          //  "c"
    NSXErrorCodeType_MachPort,      //  "I"
    NSXErrorCodeType_CFIndex        //  "q"
}   NSXErrorCodeType;

static NSXErrorCodeType NSXErrorCodeTypeFromObjCType(const char *objCType) {
    switch (objCType[0]) {
        case 's': // @encode(short)
        case 'l': // @encode(long)
            return NSXErrorCodeType_Carbon;
        case 'i': // @encode(int)
            return NSXErrorCodeType_PosixOrMach;
        case '@': // @encode(id)
            return NSXErrorCodeType_Cocoa;
        case '^': // @encode(*foo)
        case '*': // @encode(char*)
            return NSXErrorCodeType_ptr;
        case 'r': // @encode(const foo)
            return '*' == objCType[1] ? NSXErrorCodeType_ptr : NSXErrorCodeType_Unknown;
        case 'c': // @encode(char)
            return NSXErrorCodeType_BOOL;
        case 'I': // @encode(unsigned int)
            return NSXErrorCodeType_MachPort;
        case 'q': // @encode(CFIndex)
            return NSXErrorCodeType_CFIndex;
        default:
            return NSXErrorCodeType_Unknown;
    }
}

void NSXMakeErrorImp(const char *objCType_, intptr_t result_, const char *file_, unsigned line_, const char *function_, const char *code_, NSError **error_) {
    NSString *errorDomain = nil;
    int errorCode = (int)result_;
    
    switch (NSXErrorCodeTypeFromObjCType(objCType_)) {
        case NSXErrorCodeType_Cocoa:
            // codeResult's type is an id/NSObject* pointer. 0 == nil == failure.
            if (0 == result_) {
                errorDomain = @"NSCocoaErrorDomain"; // Could use NSCocoaErrorDomain symbol, but that would force us to 10.4.
                errorCode = -1;
            }
            break;
        case NSXErrorCodeType_Carbon:
            // codeResult's type is OSErr (short) or OSStatus (long). 0 == noErr == success.
            if (0 != result_) {
                errorDomain = NSOSStatusErrorDomain;
            }
            break;
        case NSXErrorCodeType_PosixOrMach:
            // codeResult's type is int, which is used for both posix error codes and mach_error_t/kern_return_t.
            // 0 means success for both, and we can differentiate posix error codes since they're always -1 (the
            // actual posix code stored in errno).
            if (0 != result_) {
                if (-1 == result_) {
                    // Posix error code.
                    errorDomain = NSPOSIXErrorDomain;
                    errorCode = errno;
                } else {
                    // Mach error code.
                    errorDomain = NSMachErrorDomain;
                }
            }
            break;
        case NSXErrorCodeType_ptr:
            // codeResult's type is some sort of non-id/non-NSObject* pointer. 0 == NULL == failure.
            if (0 == result_) {
                errorDomain = NULLPointerErrorDomain;
                errorCode = -1;
            }
            break;
        case NSXErrorCodeType_BOOL:
            // codeResult's type is a BOOL. 0 == NO == failure.
            if (0 == result_) {
                errorDomain = BOOLErrorDomain;
                errorCode = -1;
            }
            break;
        case NSXErrorCodeType_MachPort:
            // codeResult's type is a unsigned int. 0 == MACH_PORT_NULL == failure.
            if (!MACH_PORT_VALID((mach_port_name_t)result_)) {
                errorDomain = NSMachErrorDomain;
                errorCode = -1;
            }
            break;
        case NSXErrorCodeType_CFIndex:
            // codeResult's type is a CFIndex, which seems only used by CFSocket, CFStream (deprecated) and CFURLAccess.
            // 0 == (0|kCFSocketSuccess) == success.
            if (0 != result_) {
                errorDomain = @"CFSocketErrorDomain";
            }
            break;
        default:
            NSCAssert1(NO, @"NSXErrorCodeType_Unknown: \"%s\"", objCType_);
            break;
    }
    
    if (errorDomain) {
        *error_ = [NSError errorWithDomain:errorDomain
                                      code:errorCode
                                  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSString stringWithUTF8String:file_],   @"__FILE__",
                                            [NSNumber numberWithInt:line_],   @"__LINE__",
                                            [NSString stringWithUTF8String:function_], @"__PRETTY_FUNCTION__",
                                            [NSString stringWithUTF8String:code_], @"CODE",
                                            nil]];
    }
}
