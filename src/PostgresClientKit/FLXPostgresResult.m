
#include <libpq-fe.h>
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresResult

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithResult:(void* )theResult types:(FLXPostgresTypes* )theTypes {
	NSParameterAssert(theResult);
	self = [super init];
	if(self) {
		m_theResult = theResult;
		m_theTypes = [theTypes retain];
		m_theNumberOfRows = PQntuples([self result]);
		m_theAffectedRows = [[NSString stringWithUTF8String:PQcmdTuples([self result])] retain];
		m_theRow = 0;
	}
	return self;
}

-(void)dealloc {
	PQclear(m_theResult);
	[m_theTypes release];
	[m_theAffectedRows release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// private

-(PGresult* )result {
	return m_theResult;
}

-(FLXPostgresTypes* )types {
	return m_theTypes;
}

-(NSObject* )objectForCell:(NSUInteger)theRow column:(NSUInteger)theColumn {
	// check for null
	if(PQgetisnull([self result],theRow,theColumn)) {
		return [NSNull null];
	}
	// get type, bytes, length for column
	// NOTE: is there an overflow problem returning int from PQgetlength? can we reach 4GB?
	FLXPostgresType theType = [self typeForColumn:theColumn];	
	const char* theBytes = PQgetvalue([self result],theRow,theColumn);
	NSUInteger theLength = PQgetlength([self result],theRow,theColumn);
	// perform conversion depending on type
	switch(theType) {      
	case FLXPostgresTypeString:
		return [FLXPostgresTypes stringFromBytes:theBytes length:theLength];
	case FLXPostgresTypeInteger:
		return [FLXPostgresTypes integerFromBytes:theBytes length:theLength];
	case FLXPostgresTypeReal:
		return [FLXPostgresTypes realFromBytes:theBytes length:theLength];
	case FLXPostgresTypeBool:
		return [FLXPostgresTypes booleanFromBytes:theBytes length:theLength];
	case FLXPostgresTypeData:
		return [FLXPostgresTypes dataFromBytes:theBytes length:theLength];
	case FLXPostgresTypeDate:
		return [FLXPostgresTypes dateFromBytes:theBytes length:theLength];
	case FLXPostgresTypeDatetime:
		return [FLXPostgresTypes datetimeFromBytes:theBytes length:theLength];
	}
	// unsupported type
	NSString* theTypeString = [[self types] stringAtIndex:PQftype([self result],theColumn)];
	[FLXPostgresException raise:@"FLXPostgresConnectionError" 
						 reason:[NSString stringWithFormat:@"Unsupported data type returned from database: %@",theTypeString]];
	return nil;	
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
	if([self types]) {
		return [[self types] typeAtIndex:PQftype([self result],theColumn)];
	} else {
		return FLXPostgresTypeUnknown;
	}
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
	for(NSUInteger i = 0; i < [self numberOfColumns]; i++) {
		[theRowArray addObject:[self objectForCell:m_theRow column:i]];
	}
	// increment to next row
	m_theRow++;
	// return the array
	return theRowArray;
}

@end
