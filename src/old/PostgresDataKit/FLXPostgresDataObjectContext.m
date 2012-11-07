
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

@implementation FLXPostgresDataObjectContext

@synthesize className;
@synthesize schema;
@synthesize tableName;
@synthesize primaryKey;
@synthesize serialKey;
@synthesize tableColumns;
@synthesize type;

///////////////////////////////////////////////////////////////////////////////

-(void)dealloc {
	[self setClassName:nil];
	[self setSchema:nil];
	[self setTableName:nil];
	[self setPrimaryKey:nil];
	[self setSerialKey:nil];
	[self setTableColumns:nil];
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////

-(NSString* )tableSchemaName {
	if([[self schema] length]) {
		return [NSString stringWithFormat:@"%@.%@",[self schema],[self tableName]];
	} else {
		return [self tableName];
	}
}

-(NSString* )description {
	switch([self type]) {
		case FLXPostgresDataObjectSimple:
			return [NSString stringWithFormat:@"{%@ => %@, primary key = %@, columns = { %@ }}",[self className],[self tableSchemaName],[self primaryKey],[[self tableColumns] componentsJoinedByString:@","]];
		default:
			return [super description];
	}
}

@end
