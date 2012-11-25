
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"


////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccessLine : PGTokenizerLine {
	NSUInteger _state;
	BOOL _comment;
	BOOL _enabled;
	PGTokenizerValue* _type;
	NSMutableArray* _user;
	NSMutableArray* _database;
	PGTokenizerValue* _address;
	PGTokenizerValue* _ipmask;
	PGTokenizerValue* _method;
	NSMutableDictionary* _options;
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccess : PGTokenizer

@end
