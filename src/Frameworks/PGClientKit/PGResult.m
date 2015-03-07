
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

@implementation PGResult

@dynamic size, numberOfColumns, affectedRows, dataReturned, columnNames, rowNumber, format;

////////////////////////////////////////////////////////////////////////////////
// initialization

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
		_cachedData = [NSMutableDictionary dictionaryWithCapacity:PQntuples(_result)];
	}
	return self;	
}

-(id)initWithResult:(PGresult* )theResult format:(PGClientTupleFormat)format {
	return [self initWithResult:theResult format:format encoding:NSUTF8StringEncoding];
}

-(void)dealloc {
	[NSThread sleepForTimeInterval:1.0];
	[_cachedData removeAllObjects];
	PQclear((PGresult* )_result);
}

////////////////////////////////////////////////////////////////////////////////

-(PGClientTupleFormat)format {
	return _format;
}

-(NSUInteger)size {
	NSUInteger _number = NSIntegerMax;
	if(_number==NSIntegerMax) {
		_number = PQntuples(_result);
	}
	return _number;
}

-(NSUInteger)numberOfColumns {
	NSUInteger _number = NSIntegerMax;
	if(_number==NSIntegerMax) {
		_number = PQnfields(_result);
	}
	return _number;
}

-(NSUInteger)affectedRows {
	NSUInteger _number = NSIntegerMax;
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
//	NSParameterAssert(size);

	switch(_format) {
		case PGClientTupleFormatText:
			return pgdata_text2obj(PQftype(_result,(int)c),bytes,size,_encoding);
		case PGClientTupleFormatBinary:
			return pgdata_bin2obj(PQftype(_result,(int)c),bytes,size,_encoding);
		default:
			return nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

// return the current row as an array of NSObject values
-(NSArray* )fetchRowAsArray {
	if(_rowNumber >= [self size]) {
		return nil;
	}
	NSNumber* key = [NSNumber numberWithUnsignedInteger:_rowNumber];
	NSMutableArray* theArray = [_cachedData objectForKey:key];
	if(theArray==nil) {
		// create the array
		NSUInteger numberOfColumns = [self numberOfColumns];
		theArray = [NSMutableArray arrayWithCapacity:numberOfColumns];
		// fill in the columns
		for(NSUInteger i = 0; i < numberOfColumns; i++) {
			id obj = [self _tupleForRow:_rowNumber column:i];
			NSParameterAssert(obj);
			[theArray addObject:obj];
		}
		// cache the array
		[_cachedData setObject:theArray forKey:key];
	}	
	// increment to next row, return
	_rowNumber++;
	return theArray;
}

-(NSDictionary* )fetchRowAsDictionary {
	return [NSDictionary dictionaryWithObjects:[self fetchRowAsArray] forKeys:[self columnNames]];
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
