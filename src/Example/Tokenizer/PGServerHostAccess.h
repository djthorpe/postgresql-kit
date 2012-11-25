
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"


////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccessLine : PGTokenizerLine {
	NSUInteger _state;
	BOOL _enabled;
	NSString* _type;
	NSString* _database;
	NSString* _user;
}

// properties
@property BOOL enabled;
@property NSString* type;
@property NSString* database;
@property NSString* user;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccess : PGTokenizer

@end
