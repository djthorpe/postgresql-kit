
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"


////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccessRule : PGTokenizerLine {
	NSUInteger _state;
	BOOL _comment;
	BOOL _enabled;
	BOOL _modified;
	PGTokenizerValue* _type;
	NSMutableArray* _user;
	NSMutableArray* _database;
	PGTokenizerValue* _address;
	PGTokenizerValue* _ipmask;
	PGTokenizerValue* _method;
	NSMutableDictionary* _options;
}

@property (readonly) BOOL modified;
@property (retain) NSString* type;
@property (retain) NSString* method;

@end

////////////////////////////////////////////////////////////////////////////////

@interface PGServerHostAccess : PGTokenizer {
	NSMutableArray* _rules;
}

-(NSUInteger)count;
-(PGServerHostAccessRule* )ruleAtIndex:(NSUInteger)index;
-(void)removeRuleAtIndex:(NSUInteger)index;
-(NSUInteger)moveRuleAtIndex:(NSUInteger)index toIndex:(NSUInteger )proposedIndex;

@end
