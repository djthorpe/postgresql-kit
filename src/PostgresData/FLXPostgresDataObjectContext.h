
#import <Foundation/Foundation.h>

@interface FLXPostgresDataObjectContext : NSObject {
	NSString* tableName;
	NSString* primaryKey;
	NSArray* tableColumns;
}

@property (retain) NSString* tableName;
@property (retain) NSString* primaryKey;
@property (retain) NSArray* tableColumns;

@end
