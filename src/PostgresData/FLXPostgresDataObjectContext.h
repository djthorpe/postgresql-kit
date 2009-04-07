
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObjectContext : NSObject {
	NSString* className;
	NSString* tableName;
	NSString* schema;
	FLXPostgresDataObjectType type;
	NSString* primaryKey;
	NSString* serialKey;
	NSArray* tableColumns;
}

@property (retain) NSString* className;
@property (retain) NSString* tableName;
@property (retain) NSString* schema;
@property (assign) FLXPostgresDataObjectType type;
@property (retain) NSString* primaryKey;
@property (retain) NSString* serialKey;
@property (retain) NSArray* tableColumns;

@end
