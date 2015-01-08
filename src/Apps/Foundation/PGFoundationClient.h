
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

#import "PGFoundationApp.h"
#import "Terminal.h"

@interface PGFoundationClient : PGFoundationApp <PGConnectionDelegate> {
	PGConnection* _db;
	Terminal* _term;
}

// properties
@property (assign) int signal;
@property (retain) PGConnection* db;
@property (retain) Terminal* term;
@property (readonly) NSString* prompt;

@end
