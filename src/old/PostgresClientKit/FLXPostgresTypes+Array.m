
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSNumber.h"

@implementation FLXPostgresTypes (Array)

// maximum number of dimensions for arrays
#define ARRAY_MAXDIM   6

////////////////////////////////////////////////////////////////////////////////////////////////
// returns YES if the NSArray to bind includes objects of the same class (and objects can be
// bound). Also returns if there are any NULL objects, and the Oid of the objects.

-(BOOL)_validBoundValueForArray:(NSArray* )theArray hasNull:(BOOL* )hasNull type:(FLXPostgresOid* )theType {
	NSParameterAssert(theArray);
	NSParameterAssert(hasNull);
	NSParameterAssert(theType);
	
	(*theType) = 0;     // init type
	(*hasNull) = NO; 	// init null flag
	
	// iterate through the objects
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
		// set the type
		FLXPostgresOid theType2 = [self boundTypeFromObject:theObject];
		if(theType2==0) {
			return NO;
		}
		if((*theType)==0) {
			(*theType) = theType2;
		} else if((*theType) != theType2) {
			return NO;
		}
	}	
	
	// if type is zero here, then set the type to text
	if((*theType)==0) {
		(*theType) = FLXPostgresTypeText;
	}	
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// return number of dimensions for NSArray - currently zero or one

-(SInt32)_dimensionsForArray:(NSArray* )theArray {
	NSParameterAssert(theArray);
	if([theArray count]==0) return 0;
	return 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// return type based on tuple type

-(FLXPostgresOid)_arrayTypeForElementType:(FLXPostgresOid)theType {
	switch(theType) {
		case FLXPostgresTypeBool:
			return FLXPostgresTypeArrayBool;
		case FLXPostgresTypeData:
			return FLXPostgresTypeArrayData;
		case FLXPostgresTypeChar:
			return FLXPostgresTypeArrayChar;
		case FLXPostgresTypeName:
			return FLXPostgresTypeArrayName;
		case FLXPostgresTypeInt2:
			return FLXPostgresTypeArrayInt2;
		case FLXPostgresTypeInt4:
			return FLXPostgresTypeArrayInt4;
		case FLXPostgresTypeText:
			return FLXPostgresTypeArrayText;
		case FLXPostgresTypeVarchar:
			return FLXPostgresTypeArrayVarchar;
		case FLXPostgresTypeInt8:
			return FLXPostgresTypeArrayInt8;
		case FLXPostgresTypeFloat4:
			return FLXPostgresTypeArrayFloat4;
		case FLXPostgresTypeFloat8:
			return FLXPostgresTypeArrayFloat8;
		case FLXPostgresTypeMacAddr:
			return FLXPostgresTypeArrayMacAddr;
		case FLXPostgresTypeIPAddr:
			return FLXPostgresTypeArrayIPAddr;
	}
	return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// return bound NSData object

-(NSObject* )boundValueFromArray:(NSArray* )theArray type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theArray);
	NSParameterAssert(theTypeOid);

	BOOL hasNull;
	FLXPostgresOid theElementType;
	NSMutableData* theBytes = [NSMutableData data];
	
	// arrays must be empty or one-dimensional, with either one supported object class type or NSNull
	if([self _validBoundValueForArray:theArray hasNull:&hasNull type:&theElementType]==NO) {
		[[self connection] _noticeProcessorWithMessage:@"Unsupported array tuples cannot be bound"];
		return nil;
	}
	NSParameterAssert(theElementType);

	// obtain array type - 0 means unsupported
	FLXPostgresOid theArrayType = [self _arrayTypeForElementType:theElementType];
	if(theArrayType==0) {
		[[self connection] _noticeProcessorWithMessage:@"Unsupported array type cannot be bound"];
		return nil;
	}
	// set the type
	(*theTypeOid) = theArrayType;
	
	// insert number of dimensions
	SInt32 dim = [self _dimensionsForArray:theArray];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	[theBytes appendData:[self boundDataFromInt32:dim]];

	// set flags - should be 0 or 1
	[theBytes appendData:[self boundDataFromInt32:(hasNull ? 1 : 0)]];

	// set the type of the tuples in the array
	[theBytes appendData:[self boundDataFromInt32:theElementType]];

	// return if dimensions is zero
	if(dim==0) {
		return theBytes;
	}
	
	// for each dimension, output the number of tuples in the dimension
	// and the lower bound (which is always zero)
	NSParameterAssert(dim==0 || dim==1);
	SInt32 theCount = [theArray count];
	SInt32 theLowerBound = 1;
	NSParameterAssert([theArray count]==theCount);
	[theBytes appendData:[self boundDataFromInt32:theCount]];
	[theBytes appendData:[self boundDataFromInt32:theLowerBound]];
	
	// append the objects
	NSUInteger i = 0;
	for(NSObject* theObject in theArray) {
		i++;
		if([theObject isKindOfClass:[NSNull class]]) {
			// output 0xFFFFFFFF
			[theBytes appendData:[self boundDataFromInt32:((SInt32)-1)]];
			continue;
		}
		FLXPostgresOid theType;
		NSData* theBoundObject = (NSData* )[self boundValueFromObject:theObject type:&theType];
		if(theBoundObject==nil) {
			[[self connection] _noticeProcessorWithMessage:[NSString stringWithFormat:@"Unable to bind array object (tuple %d)",i]];
			return nil;
		}			
		if([theBoundObject isKindOfClass:[NSData class]]==NO) {
			[[self connection] _noticeProcessorWithMessage:[NSString stringWithFormat:@"Unable to bind non-data array object (tuple %d)",i]];
			return nil;			
		}
		if(theType != theElementType) {
			[[self connection] _noticeProcessorWithMessage:[NSString stringWithFormat:@"Unable to bind array object (tuple %d), unexpected type",i]];
			return nil;			
		}
		if([theBoundObject length] > ((NSUInteger)0x7FFFFFFF)) {
			[[self connection] _noticeProcessorWithMessage:[NSString stringWithFormat:@"Unable to bind array object (tuple %d), beyond capacity",i]];
			return nil;			
		}			
		// TODO: ensure length of data is no greater than 0x7FFFFFFF
		[theBytes appendData:[self boundDataFromInt32:[theBoundObject length]]];
		[theBytes appendData:theBoundObject];			   
	}
	
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
