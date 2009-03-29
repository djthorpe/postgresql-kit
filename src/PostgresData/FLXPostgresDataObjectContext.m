
#import "PostgresDataKit.h"

@implementation FLXPostgresDataObjectContext

@synthesize tableName;
@synthesize primaryKey;
@synthesize tableColumns;

-(void)dealloc {
	[self setTableName:nil];
	[self setPrimaryKey:nil];
	[self setTableColumns:nil];
	[super dealloc];
}

@end
