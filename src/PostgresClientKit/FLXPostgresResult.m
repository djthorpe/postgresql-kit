
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresResult

@synthesize numberOfColumns = m_theNumberOfColumns;
@dynamic affectedRows;

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithResult:(PGresult* )theResult connection:(FLXPostgresConnection* )theConnection {
	NSParameterAssert(theResult);
	self = [super init];
	if(self) {
		m_theResult = theResult;
		m_theNumberOfRows = PQntuples([self result]);
		m_theNumberOfColumns = PQnfields([self result]);
		m_theAffectedRows = [[NSString stringWithUTF8String:PQcmdTuples([self result])] retain];
		m_theRow = 0;
		m_theConnection = [theConnection retain];
		m_theTypeHandlers = (void** )calloc(sizeof(void* ),m_theNumberOfColumns);
		NSParameterAssert(m_theTypeHandlers);
	}
	return self;
}

-(void)dealloc {
	PQclear(m_theResult);
	free(m_theTypeHandlers);
	[m_theAffectedRows release];
	[m_theConnection release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// private

-(PGresult* )result {
	return m_theResult;
}

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSUInteger)affectedRows {
	if([self isDataReturned]) {
		return m_theNumberOfRows;
	} else {
		return [m_theAffectedRows integerValue];
	}
}

-(NSArray* )columns {
	NSMutableArray* theColumns = [NSMutableArray arrayWithCapacity:m_theNumberOfColumns];
	for(NSUInteger i = 0; i < m_theNumberOfColumns; i++) {
		[theColumns addObject:[NSString stringWithUTF8String:PQfname([self result],i)]];
	}
	return theColumns;
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

-(id<FLXPostgresTypeProtocol>)typeHandlerForColumn:(NSUInteger)theColumn {
	NSParameterAssert(theColumn < m_theNumberOfColumns);
	void* theHandler = m_theTypeHandlers[theColumn];
	if(theHandler == nil) {
		FLXPostgresOid theType = PQftype([self result],theColumn);
		theHandler = m_theTypeHandlers[theColumn] = [m_theConnection _typeHandlerForRemoteType:theType];
	}	
	return theHandler;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSObject* )_objectForRow:(NSUInteger)theRow column:(NSUInteger)theColumn {	
	// check for null
	if(PQgetisnull([self result],theRow,theColumn)) {
		return [NSNull null];
	}
	// get bytes, length
	const void* theBytes = PQgetvalue([self result],theRow,theColumn);
	NSUInteger theLength = PQgetlength([self result],theRow,theColumn);
	FLXPostgresOid theType = PQftype([self result],theColumn);

	// get handler for this type
	id<FLXPostgresTypeProtocol> theHandler = [self typeHandlerForColumn:theColumn];
	if(theHandler==nil) {
		return [NSData dataWithBytes:theBytes length:theLength];
	} else {
		return [theHandler objectFromRemoteData:theBytes length:theLength type:theType];
	}
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
	for(NSUInteger theColumn = 0; theColumn < m_theNumberOfColumns; theColumn++) {
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
