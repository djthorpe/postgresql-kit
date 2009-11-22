
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresResult
@synthesize types = m_theTypes;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithTypes:(FLXPostgresTypes* )theTypes result:(PGresult* )theResult {
	NSParameterAssert(theResult);
	self = [super init];
	if(self) {
		m_theTypes = [theTypes retain];
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
	[m_theTypes release];
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

/*
-(FLXPostgresType)typeForColumn:(NSUInteger)theColumn {
	return (FLXPostgresType)PQftype([self result],theColumn);
}
*/

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
// provate methods

-(NSObject* )_objectForRow:(NSUInteger)theRow column:(NSUInteger)theColumn {
	// check for null
	if(PQgetisnull([self result],theRow,theColumn)) {
		return [NSNull null];
	}
	// get bytes, length
	const void* theBytes = PQgetvalue([self result],theRow,theColumn);
	NSUInteger theLength = PQgetlength([self result],theRow,theColumn);
	FLXPostgresOid theType = PQftype([self result],theColumn);
	// return object
	return [[self types] objectFromBytes:theBytes length:theLength type:theType];
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
		NSObject* theObject = [self _objectForRow:m_theRow column:theColumn];
		if(theObject==nil) {
			[FLXPostgresException raise:@"FLXPostgresResultError" reason:[NSString stringWithFormat:@"Unable to retrieve data at resultset row %u, column %u",m_theRow,theColumn]];
		}
		[theRowArray addObject:theObject];
	}
	// increment to next row
	m_theRow++;
	// return the array
	return theRowArray;
}

@end
