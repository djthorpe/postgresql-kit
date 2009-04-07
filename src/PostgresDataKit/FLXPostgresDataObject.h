
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObject : NSObject {
	FLXPostgresDataObjectContext* context;
	NSMutableDictionary* values;
	NSMutableDictionary* modifiedValues;
	BOOL modified;
}

@property (retain) NSMutableDictionary* values;
@property (retain) NSMutableDictionary* modifiedValues;
@property (assign) BOOL modified;
@property (retain) FLXPostgresDataObjectContext* context;

// methods which can be subclassed
+(NSString* )tableName;
+(NSArray* )tableColumns;
+(NSString* )primaryKey;
+(NSString* )serialKey;
+(FLXPostgresDataObjectType)objectType;

-(NSObject* )primaryValue;
-(NSObject* )valueForKey:(NSString* )theKey;
-(void)setValue:(NSObject* )theValue forKey:(NSString* )theKey;

@end
