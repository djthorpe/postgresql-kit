
#import <Foundation/Foundation.h>
#import "PGServerConfigurationLine.h"

@interface PGServerConfiguration : NSObject {
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

-(NSObject* )valueForKey:(NSString* )key;
-(NSString* )suffixForKey:(NSString* )key;
-(BOOL)enabledForKey:(NSString* )key;
-(NSString* )commentForKey:(NSString* )key;

-(void)setValue:(NSObject* )value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;
-(void)setString:(NSString* )value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;
-(void)setInteger:(NSInteger)value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;
-(void)setDouble:(double)value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;
-(void)setBool:(BOOL)value enabled:(BOOL)enabled forKey:(NSString* )key error:(NSError** )error;

@end
