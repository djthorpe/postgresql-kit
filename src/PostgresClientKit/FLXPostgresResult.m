
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresResult

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithResult:(PGresult* )theResult {
	NSParameterAssert(theResult);
	self = [super init];
	if(self) {
		m_theResult = theResult;
		m_theNumberOfRows = PQntuples([self result]);
		m_theAffectedRows = [[NSString stringWithUTF8String:PQcmdTuples([self result])] retain];
		m_theRow = 0;
	}
	return self;
}

-(void)dealloc {
	PQclear(m_theResult);
	[m_theAffectedRows release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// private

-(PGresult* )result {
	return m_theResult;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSUInteger)numberOfColumns {
	return PQnfields([self result]);
}

-(NSUInteger)affectedRows {
	if([self isDataReturned]) {
		return m_theNumberOfRows;
	} else {
		return [m_theAffectedRows integerValue];
	}
}

-(NSArray* )columns {
	NSMutableArray* theColumns = [NSMutableArray arrayWithCapacity:[self numberOfColumns]];
	for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
		[theColumns addObject:[NSString stringWithUTF8String:PQfname([self result],i)]];
	}
	return theColumns;
}

-(FLXPostgresType)typeForColumn:(NSUInteger)theColumn {
	return (FLXPostgresType)PQftype([self result],theColumn);
}

-(NSInteger)modifierForColumn:(NSUInteger)theColumn {
	return (NSInteger)PQfmod([self result],theColumn);
}

-(NSUInteger)sizeForColumn:(NSUInteger)theColumn {
	// NOTE: is there an overflow problem returning int?
	return PQfsize([self result],theColumn);
}

-(BOOL)isDataReturned {
	return PQresultStatus([self result])==PGRES_TUPLES_OK ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)dataSeek:(NSUInteger)theRow {
	if(theRow >= [self affectedRows]) {
		[FLXPostgresException raise:@"FLXPostgresResultError" reason:@"Seeking beyond last result row"];
	}
	m_theRow = theRow;
}

-(NSArray* )fetchRowAsArray {
	// boundary test
	if(m_theRow >= m_theNumberOfRows) {
		return nil;
	}
	// create the array
	NSMutableArray* theRowArray = [NSMutableArray arrayWithCapacity:[self numberOfColumns]];
	// fill in the columns
	for(NSUInteger theColumn = 0; theColumn < [self numberOfColumns]; theColumn++) {
		[theRowArray addObject:[FLXPostgresTypes objectForResult:[self result] row:m_theRow column:theColumn]];
	}
	// increment to next row
	m_theRow++;
	// return the array
	return theRowArray;
}

@end
