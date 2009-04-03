
#import "PostgresDataKit.h"

@implementation FLXPostgresDataObjectContext

@synthesize className;
@synthesize database;
@synthesize schema;
@synthesize tableName;
@synthesize primaryKey;
@synthesize tableColumns;
@synthesize type;

-(id)init {
	self = [super init];
	if (self != nil) {
		// we only support simple object types at the moment
		[self setType:FLXPostgresDataObjectSimple];
	}
	return self;
}

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
	switch([self type]) {
		case FLXPostgresDataObjectSimple:
			return [NSString stringWithFormat:@"{%@ => %@.%@.%@, primary key = %@, columns = { %@ }}",[self className],[self database],[self schema],[self tableName],[self primaryKey],[[self tableColumns] componentsJoinedByString:@","]];
		default:
			return [super description];
	}
}

@end
