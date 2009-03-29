
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObject : NSObject {
	NSMutableDictionary* values;
}

@property (retain) NSMutableDictionary* values;

+(NSString* )tableName;
+(NSArray* )tableColumns;
-(NSObject* )primaryValue;
-(NSObject* )valueForKey:(NSString* )theKey;
-(void)setValue:(NSObject* )theObject forKey:(NSString* )theKey;
-(BOOL)isModified;

@end
