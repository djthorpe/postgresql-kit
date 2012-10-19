
#import <Foundation/Foundation.h>

@class PGClient;
@class PGStatement;

typedef enum {
	PGConnectionStatusDisconnected = 0,
	PGConnectionStatusBad = -1,
	PGConnectionStatusConnected = 1
} PGConnectionStatus;

#import "PGClient.h"
#import "PGStatement.h"

