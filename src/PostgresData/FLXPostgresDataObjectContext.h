
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObjectContext : NSObject {
	NSString* className;
	NSString* schema;
	FLXPostgresDataObjectType type;

	NSString* tableName;
	NSString* primaryKey;
	NSArray* tableColumns;
}

@property (retain) NSString* className;
@property (retain) NSString* schema;
@property (assign) FLXPostgresDataObjectType type;

@property (retain) NSString* tableName;
@property (retain) NSString* primaryKey;
@property (retain) NSArray* tableColumns;

@end
