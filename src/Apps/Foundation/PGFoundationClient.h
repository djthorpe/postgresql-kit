
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

#import "PGFoundationApp.h"
#import "Terminal.h"

@interface PGFoundationClient : PGFoundationApp <PGConnectionDelegate> {
	PGConnection* _db;
	PGPasswordStore* _password;
	Terminal* _term;
}

// properties
@property (readonly) NSURL* url;
@property (readonly) BOOL useKeychain;
@property (readonly) NSString* prompt;
@property (readonly) PGConnection* db;
@property (readonly) Terminal* term;
@property (readonly) PGPasswordStore* password;

@end
