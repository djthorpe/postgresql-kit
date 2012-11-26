
#import "PGClientKit.h"
#import "PGClientKit+Private.h"

@implementation PGResult

@dynamic size, numberOfColumns, affectedRows, dataReturned, columnNames, rowNumber, format;

////////////////////////////////////////////////////////////////////////////////
// initialization

+(void)initialize {
	_pgresult_cache_init();
}

-(id)init {
	return nil;
}

-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format encoding:(NSStringEncoding)encoding {
	self = [super init];
	if(self) {
		NSParameterAssert(theResult);
		_result = theResult;
		_format = format;
		_encoding = encoding;

	}
	return self;	
}

-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format {
	return [self initWithResult:theResult format:format encoding:NSUTF8StringEncoding];
}

-(void)dealloc {
	PQclear((PGresult* )_result);
}

////////////////////////////////////////////////////////////////////////////////

-(PGClientTupleFormat)format {
	return _format;
}

-(NSUInteger)size {
	static NSUInteger _number = NSIntegerMax;
	if(_number==NSIntegerMax) {
		_number = PQntuples(_result);
	}
	return _number;
}

-(NSUInteger)numberOfColumns {
	static NSUInteger _number = NSIntegerMax;
	if(_number==NSIntegerMax) {
		_number = PQnfields(_result);
	}
	return _number;
}

-(NSUInteger)affectedRows {
	static NSUInteger _number = NSIntegerMax;
	if(_number==NSIntegerMax) {
		NSString* affectedRows = [NSString stringWithUTF8String:PQcmdTuples(_result)];
		_number = [affectedRows integerValue];
	}
	return _number;
}

-(BOOL)dataReturned {
	return PQresultStatus(_result)==PGRES_TUPLES_OK ? YES : NO;
}

-(NSArray* )columnNames {
	NSUInteger numberOfColumns = [self numberOfColumns];
	NSMutableArray* theColumns = [NSMutableArray arrayWithCapacity:numberOfColumns];
	for(NSUInteger i = 0; i < numberOfColumns; i++) {
		[theColumns addObject:[NSString stringWithUTF8String:PQfname(_result,(int)i)]];
	}
	return theColumns;
}

-(void)setRowNumber:(NSUInteger)rowNumber {
	NSParameterAssert(rowNumber < [self size]);
	_rowNumber = rowNumber;
}

-(NSUInteger)rowNumber {
	return _rowNumber;	
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSObject* )_tupleForRow:(NSUInteger)r column:(NSUInteger)c {
	// check for null
	if(PQgetisnull(_result,(int)r,(int)c)) {
		return [NSNull null];
	}
	// get bytes, length
	const void* bytes = PQgetvalue(_result,(int)r,(int)c);
	NSUInteger size = PQgetlength(_result,(int)r,(int)c);
	NSParameterAssert(bytes);
	NSParameterAssert(size);

	// text return
	if(_format==PGClientTupleFormatText) {
		return [[NSString alloc] initWithBytes:bytes length:size encoding:_encoding];
	}
	
	// binary return
	NSParameterAssert(_format==PGClientTupleFormatBinary);
	return _pgresult_bin2obj(PQftype(_result,(int)c),bytes,size);
}

////////////////////////////////////////////////////////////////////////////////

// return the current row as an array of NSObject values
-(NSArray* )fetchRowAsArray {
	if(_rowNumber >= [self size]) {
		return nil;
	}
	// create the array
	NSUInteger numberOfColumns = [self numberOfColumns];
	NSMutableArray* theArray = [NSMutableArray arrayWithCapacity:numberOfColumns];
	// fill in the columns
	for(NSUInteger i = 0; i < numberOfColumns; i++) {
		[theArray addObject:[self _tupleForRow:_rowNumber column:i]];
	}
	// increment to next row, return
	_rowNumber++;
	return theArray;
}

////////////////////////////////////////////////////////////////////////////////

-(NSString* )description {
	NSDictionary* theValues =
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInteger:[self size]],@"size",
			[NSNumber numberWithUnsignedInteger:[self affectedRows]],@"affectedRows",
			[NSNumber numberWithBool:[self dataReturned]],@"dataReturned",
		 	[self columnNames],@"columnNames",nil];
	return [theValues description];
}

@end
