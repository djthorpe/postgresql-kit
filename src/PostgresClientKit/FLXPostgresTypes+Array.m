
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSNumber.h"

@implementation FLXPostgresTypes (Array)

// maximum number of dimensions for arrays
#define ARRAY_MAXDIM   6

////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL)_validBoundValueForArray:(NSArray* )theArray hasNull:(BOOL* )hasNull type:(FLXPostgresOid* )theTypePtr {
	NSParameterAssert(theArray);
	NSParameterAssert(hasNull);
	NSParameterAssert(theTypePtr);
	
	FLXPostgresOid theType = 0;
	(*hasNull) = NO; 	// init null flag

	for(NSObject* theObject in theArray) {
		// we allow NSNull objects regardless
		if([theObject isKindOfClass:[NSNull class]]) {
			(*hasNull) = YES;
			continue;
		}
		// we don't allow nested arrays
		if([theObject isKindOfClass:[NSArray class]]) {
			return NO;
		}
		// set the class
		if(theType==0) {
			theType = [self typeForObject:theObject];
			continue;
		}
		// ensure all objects have the same class
		if([theObject isKindOfClass:theClass]==NO) {
			return NO;
		}
	}	
	
	return YES;
}

-(Int32)_dimensionsForArray:(NSArray* )theArray {
	NSParameterAssert(theArray);
	if([theArray count]==0) return 0;
	return 1;
}

-(NSObject* )boundValueFromArray:(NSArray* )theArray type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theArray);
	NSParameterAssert(theTypeOid);

	BOOL hasNull;
	FLXPostgresOid theType;
	NSMutableData* theBytes = [NSMutableData data];
	
	// arrays must be empty or one-dimensional, with either one class or NSNull
	if([self _validBoundValueForArray:theArray hasNull:&hasNull type:&theType]==NO) {
		return nil;
	}
	
	// insert number of dimensions
	Int32 dim = [self _dimensionsForArray:theArray];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	[theBytes appendData:[self boundDataFromInt32:dim]];

	// if dimensions is zero, return directly
	if(dim==0) return theBytes;

	// set flags - should be 0 or 1
	[theBytes appendData:[self boundDataFromInt32:(hasNull ? 1 : 0)]];
	
	// set the type of the tuples in the array
	
	
	return theBytes;
	
}

////////////////////////////////////////////////////////////////////////////////////////////////
// arrays

-(NSObject* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	// use 4 byte alignment
	const UInt32* thePtr = theBytes;
	// get number of dimensions - we allow zero-dimension arrays
	NSInteger dim = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// return empty array if dim is zero
	if(dim==0) return [NSArray array];	
	// get flags - should be zero or one
	NSInteger flags = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(flags==0 || flags==1);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// get type of array
	FLXPostgresOid type = [[self unsignedIntegerObjectFromBytes:(thePtr++) length:4] unsignedIntegerValue];
	NSParameterAssert(type==theType);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	
	// create an array to hold tuples
	FLXPostgresArray* theArray = [FLXPostgresArray arrayWithDimensions:dim type:type];
	NSParameterAssert(theArray);
	
	// for each dimension, retrieve dimension and lower bound
	NSInteger tuples = dim ?  1 : 0;
	for(NSInteger i = 0; i < dim; i++) {
		NSInteger dimsize = [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSInteger bound =  [[self integerObjectFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSParameterAssert(dimsize > 0);
		NSParameterAssert(bound >= 0);		
		// set dim-n size and lower bound
		[theArray setDimension:i size:dimsize lowerBound:bound];
		// calculate number of tuples
		tuples = tuples * dimsize;
	}	
	// iterate through the tuples
	for(NSInteger i = 0; i < tuples; i++) {
		NSUInteger length = [[self unsignedIntegerObjectFromBytes:(thePtr++) length:4] unsignedIntegerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSObject* theObject = nil;
		if(length==((NSUInteger)0xFFFFFFFF)) {
			theObject = [NSNull null];
			length = 0;
		} else {
			theObject = [self objectFromBytes:thePtr length:length type:theType];
		}
		NSParameterAssert(theObject);
		// add tuple
		[theArray addTuple:theObject];
		// increment ptr by bytes
		thePtr = (const UInt32* )((const UInt8* )thePtr + length);
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	}
	
	// if the array is one-dimensional, return an NSArray or else return the FLXPostgresArray type
	if(dim==1) {
		return [theArray array];
	} else {
		return theArray;
	}
}

@end
