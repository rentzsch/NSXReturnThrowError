// NSXReturnThrowError.h semver:2.0.0
//   Copyright (c) 2007-2011 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/MIT
//   https://github.com/rentzsch/NSXReturnThrowError

#import <Foundation/Foundation.h>

extern NSString *NSXErrorExceptionName;
extern NSString *NULLPointerErrorDomain;
extern NSString *BOOLErrorDomain;
extern NSString *AssertionFailureErrorDomain;

void NSXMakeErrorImp(const char *objCType_, intptr_t result_, const char *file_, unsigned line_, const char *function_, const char *code_, NSError **error_);

#define NSXMakeError(ERROR, CODE)                                                                                                   \
    do{                                                                                                                             \
        typeof(CODE) codeResult = (CODE);                                                                                           \
        if (!ERROR) {                                                                                                               \
            NSXMakeErrorImp(@encode(typeof(CODE)), (intptr_t)codeResult, __FILE__, __LINE__, __PRETTY_FUNCTION__, #CODE, &ERROR);   \
        }                                                                                                                           \
    } while(0)

#define    NSXReturnError(CODE)    NSXMakeError(error, CODE)
 
#define NSXRaiseError(ERROR)                                \
    [[NSException exceptionWithName:NSXErrorExceptionName   \
                             reason:[error description]     \
                           userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]] raise];

#define NSXThrowError(CODE)         \
    do{                             \
        NSError *error = nil;       \
        NSXReturnError(CODE);       \
        if (error) {                \
            NSXRaiseError(ERROR);   \
        }                           \
    }while(0)

/* Assertion support */

#define NSXAssertToError(CODE)                                                                                  \
    if (!(CODE)) {                                                                                              \
        error = [NSError errorWithDomain:AssertionFailureErrorDomain                                            \
                                    code:1                                                                      \
                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:                            \
                                    [NSString stringWithUTF8String:__FILE__],   @"reportingFile",               \
                                    [NSNumber numberWithInt:__LINE__],   @"reportingLine",                      \
                                    [NSString stringWithUTF8String:__PRETTY_FUNCTION__], @"reportingMethod",    \
                                    [NSString stringWithUTF8String:#CODE], @"origin",                           \
                                    nil]];                                                                      \
    }
