
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObject : NSObject {
	NSMutableDictionary* values;
	BOOL modified;
}

@property (retain) NSMutableDictionary* values;
@property (assign) BOOL modified;

+(NSString* )tableName;
+(NSArray* )tableColumns;
+(NSString* )primaryKey;

/*
-(NSObject* )primaryValue;

-(NSObject* )valueForKey:(NSString* )theKey;
-(void)setValue:(NSObject* )theObject forKey:(NSString* )theKey;
*/

@end
