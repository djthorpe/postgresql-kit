
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

#import "PGFoundationApp.h"
#import "Terminal.h"

@interface PGFoundationClient : PGFoundationApp <PGConnectionDelegate> {
	PGConnection* _db;
	Terminal* _term;
}

// properties
@property (readonly) NSURL* url;
@property (readonly) NSString* prompt;
@property (retain) PGConnection* db;
@property (retain) Terminal* term;

@end
