
#import <Foundation/Foundation.h>

// typedefs
typedef enum {
	PGConnectionStatusDisconnected = 0,
	PGConnectionStatusConnected = 1,
	PGConnectionStatusRejected = 2
} PGConnectionStatus;

typedef enum {
	PGClientTupleFormatText = 0,
	PGClientTupleFormatBinary = 1
} PGClientTupleFormat;

typedef enum {
	PGClientErrorNone = 0,          // no error occured
	PGClientErrorState = 100,       // state is wrong for this call
	PGClientErrorParameters,        // invalid parameters
	PGClientErrorNeedsPassword,     // password required
	PGClientErrorInvalidPassword,   // password failure
	PGClientErrorRejected,          // rejected from operation
	PGClientErrorExecute,           // execution error
	PGClientErrorUnknown,           // unknown error
} PGClientErrorDomainCode;

extern NSString* PGClientErrorDomain;

////////////////////////////////////////////////////////////////////////////////

// forward class declarations
@class PGConnection;
@class PGResult;
@class PGStatement;
@class PGPasswordStore;

// header includes
#import "PGConnection.h"
#import "PGResult.h"
#import "PGStatement.h"

// helpers
#import "NSURL+PGAdditions.h"
#import "PGPasswordStore.h"

#if TARGET_OS_IPHONE
// Do not import additional header files
#else
// Import Mac OS X specific header files
#import "PGClientKit+Cocoa.h"
#import "PGResult+TextTable.h"
#endif
