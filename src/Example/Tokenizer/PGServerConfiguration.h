
#import <Foundation/Foundation.h>
#import "PGTokenizer.h"
#import "PGServerConfigurationLine.h"

@interface PGServerConfiguration : PGTokenizer {
	NSString* _path;
	NSMutableArray* _lines;
	NSMutableArray* _keys;
	NSMutableDictionary* _index;
	BOOL _modified;
}

// constructor
-(id)initWithPath:(NSString* )path;

// properties
@property (readonly) NSString* path;
@property (readonly) BOOL modified;
@property (readonly) NSArray* keys;
@property (readonly) NSArray* lines;

// public methods
-(BOOL)append:(PGServerConfigurationLine* )line;
-(BOOL)load;

-(NSObject* )objectForKey:(NSString* )key;
-(NSString* )suffixForKey:(NSString* )key;
-(BOOL)enabledForKey:(NSString* )key;
-(NSString* )commentForKey:(NSString* )key;
//-(void)setObject:(NSObject* )value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;

@end
