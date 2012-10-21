
#import <Foundation/Foundation.h>

// typedefs
typedef enum {
	PGConnectionStatusDisconnected = 0,
	PGConnectionStatusConnecting = 1,
	PGConnectionStatusBad = -1,
	PGConnectionStatusRejected = -2,
	PGConnectionStatusConnected = 2
} PGConnectionStatus;

typedef enum {
	PGClientTupleFormatText = 0,
	PGClientTupleFormatBinary = 1
} PGClientTupleFormat;

// forward class declarations
@class PGConnection;
@class PGResult;
@class PGStatement;

// header includes
#import "PGConnection.h"
#import "PGResult.h"
#import "PGStatement.h"

