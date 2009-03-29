
#import "PostgresDataKit.h"

@implementation FLXPostgresDataObjectContext

@synthesize className;
@synthesize database;
@synthesize schema;
@synthesize tableName;
@synthesize primaryKey;
@synthesize tableColumns;

-(void)dealloc {
	[self setClassName:nil];
	[self setDatabase:nil];
	[self setSchema:nil];
	[self setTableName:nil];
	[self setPrimaryKey:nil];
	[self setTableColumns:nil];
	[super dealloc];
}

-(NSString* )description {
	return [NSString stringWithFormat:@"{%@ => %@.%@.%@, primary key = %@, columns = { %@ }}",
			[self className],[self database],[self schema],[self tableName],[self primaryKey],[[self tableColumns] componentsJoinedByString:@","]];
}

@end
