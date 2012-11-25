
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"


////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccessLine : PGTokenizerLine {
	NSUInteger _state;
	BOOL _comment;
	BOOL _enabled;
	NSString* _type;
	NSMutableArray* _database;
	NSMutableArray* _user;
	NSString* _ip4addr;
	NSString* _ip6addr;
	NSString* _ipmask;
	NSString* _host;
	NSString* _method;
}

// properties
@property BOOL enabled;
@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccess : PGTokenizer

@end
