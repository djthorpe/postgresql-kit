
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObjectContext : NSObject {
	NSString* className;
	NSString* database;
	NSString* schema;
	NSString* tableName;
	NSString* primaryKey;
	NSArray* tableColumns;
}

@property (retain) NSString* className;
@property (retain) NSString* database;
@property (retain) NSString* schema;
@property (retain) NSString* tableName;
@property (retain) NSString* primaryKey;
@property (retain) NSArray* tableColumns;

@end
