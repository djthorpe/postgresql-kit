
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

@implementation FLXPostgresDataObjectContext

@synthesize className;
@synthesize schema;
@synthesize tableName;
@synthesize primaryKey;
@synthesize tableColumns;
@synthesize type;

///////////////////////////////////////////////////////////////////////////////

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
	[self setSchema:nil];
	[self setTableName:nil];
	[self setPrimaryKey:nil];
	[self setTableColumns:nil];
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////

-(IMP)implementationForSelector:(SEL)aSEL {
	NSLog(@"implementation for selector: %@",NSStringFromSelector(aSEL));
	return nil;
}


///////////////////////////////////////////////////////////////////////////////

-(NSString* )description {
	switch([self type]) {
		case FLXPostgresDataObjectSimple:
			return [NSString stringWithFormat:@"{%@ => %@.%@, primary key = %@, columns = { %@ }}",[self className],[self schema],[self tableName],[self primaryKey],[[self tableColumns] componentsJoinedByString:@","]];
		default:
			return [super description];
	}
}

@end
