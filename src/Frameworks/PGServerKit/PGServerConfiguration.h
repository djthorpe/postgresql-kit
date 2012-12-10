
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"

////////////////////////////////////////////////////////////////////////////////

@interface PGServerConfigurationKeyValue : PGTokenizerLine {
	NSUInteger _state;
	BOOL _enabled;
	BOOL _modified;
	NSString* _key;
	PGTokenizerValue* _value;
	NSMutableString* _comment;
}

// properties
@property BOOL enabled;
@property (readonly) NSString* key;
@property PGTokenizerValue* value;
@property (readonly) NSString* comment;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerConfiguration : PGTokenizer {
	NSMutableArray* _keys;
	NSMutableDictionary* _index;
}

// properties
@property (readonly) NSArray* keys;

// methods
-(PGTokenizerValue* )valueForKey:(NSString* )key;
-(BOOL)enabledForKey:(NSString* )key;
-(NSString* )commentForKey:(NSString* )key;

@end
