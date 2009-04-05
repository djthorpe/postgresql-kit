
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

////////////////////////////////////////////////////////////////////////////////////////////////

// for intervals and timestamps, make sure we're not using Int64 types
// but double float types - could be changed later if necessary
#undef HAVE_INT64_TIMESTAMP

// number of microseconds per second
#define USECS_PER_SEC ((double)1000000)

// maximum number of dimensions for arrays
#define ARRAY_MAXDIM   6

////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresTypes

////////////////////////////////////////////////////////////////////////////////////////////////

-(id)init {
	self = [super init];
	if (self != nil) {
		m_theDictionary = [[NSMutableDictionary alloc] init];
		m_theReverseDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc {
	[m_theReverseDictionary release];
	[m_theDictionary release];
	[super dealloc];
}


+(FLXPostgresTypes* )array {
	return [[[FLXPostgresTypes alloc] init] autorelease];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// text from object

-(NSString* )textFromObject:(NSString* )theObject {
	NSParameterAssert(theObject);
	if([theObject isKindOfClass:[NSNull class]]) {
		
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////
// object from data

-(NSObject* )objectFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	switch(theType) {
		case FLXPostgresTypeChar:
		case FLXPostgresTypeName:
		case FLXPostgresTypeText:
		case FLXPostgresTypeVarchar:
		case FLXPostgresTypeUnknown:
			return [self stringFromBytes:theBytes length:theLength];			
		case FLXPostgresTypeInt8:
		case FLXPostgresTypeInt2:
		case FLXPostgresTypeInt4:
			return [self integerFromBytes:theBytes length:theLength];
		case FLXPostgresTypeOid:
			return [self unsignedIntegerFromBytes:theBytes length:theLength];			
		case FLXPostgresTypeFloat4:
		case FLXPostgresTypeFloat8:
			return [self realFromBytes:theBytes length:theLength];
		case FLXPostgresTypeBool:
			return [self booleanFromBytes:theBytes length:theLength];
		case FLXPostgresTypeAbsTime:
			return [self abstimeFromBytes:theBytes length:theLength];
		case FLXPostgresTypeDate:
			return [self dateFromBytes:theBytes length:theLength];				
		case FLXPostgresTypeTimestamp:
			return [self timestampFromBytes:theBytes length:theLength];	
		case FLXPostgresTypeInterval:
			return [self intervalFromBytes:theBytes length:theLength];
		case FLXPostgresTypeMacAddr:
			return [self macaddrFromBytes:theBytes length:theLength];
		case FLXPostgresTypePoint:
			return [self pointFromBytes:theBytes length:theLength];
		case FLXPostgresTypeArrayInt4:
			return [self arrayFromBytes:theBytes length:theLength type:FLXPostgresTypeInt4];	
		case FLXPostgresTypeArrayText:
			return [self arrayFromBytes:theBytes length:theLength type:FLXPostgresTypeText];	
		case FLXPostgresTypeData:
			return [self dataFromBytes:theBytes length:theLength];
		default:
			NSLog(@"Unknown type, %d, returning data",theType);
			return [self dataFromBytes:theBytes length:theLength];
	}
}

-(NSObject* )objectForResult:(PGresult* )theResult row:(NSUInteger)theRow column:(NSUInteger)theColumn {
	// check for null
	if(PQgetisnull(theResult,theRow,theColumn)) {
		return [NSNull null];
	}
	// get bytes, length
	const void* theBytes = PQgetvalue(theResult,theRow,theColumn);
	NSUInteger theLength = PQgetlength(theResult,theRow,theColumn);
	FLXPostgresOid theType = PQftype(theResult,theColumn);
	// return object
	return [self objectFromBytes:theBytes length:theLength type:theType];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// string

-(NSString* )stringFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	// note that the string is always terminated with NULL so we don't need the length field
	return [NSString stringWithUTF8String:theBytes];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// integer and unsigned integer

-(NSNumber* )integerFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==2 || theLength==4 || theLength==8);
#if defined(__ppc__) || defined(__ppc64__)
	switch(theLength) {
		case 2:
			return [NSNumber numberWithShort:*((SInt16* )theBytes)];
		case 4:
			return [NSNumber numberWithInteger:*((SInt32* )theBytes)];
		case 8:
			return [NSNumber numberWithLongLong:*((SInt64* )theBytes)];
	}
#else
	switch(theLength) {
		case 2:
			return [NSNumber numberWithShort:EndianS16_BtoN(*((SInt16* )theBytes))];
		case 4:
			return [NSNumber numberWithInteger:EndianS32_BtoN(*((SInt32* )theBytes))];
		case 8:
			return [NSNumber numberWithLongLong:EndianS64_BtoN(*((SInt64* )theBytes))];
	}	
#endif
	return nil;
}


-(NSNumber* )unsignedIntegerFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==2 || theLength==4 || theLength==8);
#if defined(__ppc__) || defined(__ppc64__)
	switch(theLength) {
		case 2:
			return [NSNumber numberWithUnsignedShort:*((SInt16* )theBytes)];
		case 4:
			return [NSNumber numberWithUnsignedInteger:*((SInt32* )theBytes)];
		case 8:
			return [NSNumber numberWithUnsignedLongLong:*((SInt64* )theBytes)];
	}
#else
	switch(theLength) {
		case 2:
			return [NSNumber numberWithUnsignedShort:EndianS16_BtoN(*((SInt16* )theBytes))];
		case 4:
			return [NSNumber numberWithUnsignedInteger:EndianS32_BtoN(*((SInt32* )theBytes))];
		case 8:
			return [NSNumber numberWithUnsignedLongLong:EndianS64_BtoN(*((SInt64* )theBytes))];
	}	
#endif
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// real (floating point numbers)

-(NSNumber* )realFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4 || theLength==8);
#if defined(__ppc__) || defined(__ppc64__)
	switch(theLength) {
	case 4:
		return [NSNumber numberWithFloat:*((Float32* )theBytes)];
	case 8:
		return [NSNumber numberWithDouble:*((Float64* )theBytes)];
	}
#else
    union { Float64 r; UInt64 i; } u64;
    union { Float32 r; UInt32 i; } u32;
	switch(theLength) {
		case 4:
			u32.r = *((Float32* )theBytes);		
			u32.i = CFSwapInt32HostToBig(u32.i);			
			return [NSNumber numberWithFloat:u32.r];
		case 8:
			u64.r = *((Float64* )theBytes);		
			u64.i = CFSwapInt64HostToBig(u64.i);			
			return [NSNumber numberWithFloat:u64.r];
	}	
#endif
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// boolean

-(NSNumber* )booleanFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==1);
	return [NSNumber numberWithBool:(*((const int8_t* )theBytes) ? YES : NO)];	
}

////////////////////////////////////////////////////////////////////////////////////////////////
// data (bytea)

-(NSData* )dataFromBytes:(const void* )theBytes length:(NSUInteger)theLength {	
	NSParameterAssert(theBytes);
	return [NSData dataWithBytes:theBytes length:theLength];	
}

////////////////////////////////////////////////////////////////////////////////////////////////
// abstime

-(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength {	
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// convert bytes into integer
	NSNumber* theTime = [self integerFromBytes:theBytes length:theLength];
	return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[theTime doubleValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// date

-(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// this is number of days since 1st January 2000
	NSNumber* theDays = [self integerFromBytes:theBytes length:theLength];
	NSCalendarDate* theEpoch = [NSCalendarDate dateWithYear:2000 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
	NSCalendarDate* theDate = [theEpoch dateByAddingYears:0 months:0 days:[theDays integerValue] hours:0 minutes:0 seconds:0];	
	[theDate setCalendarFormat:@"%Y-%m-%d"];
	return theDate;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// timestamp

-(NSDate* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==8);
	NSCalendarDate* theEpoch = [NSCalendarDate dateWithYear:2000 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
#ifdef HAVE_INT64_TIMESTAMP	
	// this is number of microseconds since 1st January 2000 - I THINK
	NSNumber* theMicroseconds = [self integerFromBytes:theBytes length:theLength];	
	return [theEpoch addTimeInterval:([theMicroseconds doubleValue] * USECS_PER_SEC)];
#else
	NSNumber* theSeconds = [self realFromBytes:theBytes length:theLength];	
	return [theEpoch addTimeInterval:[theSeconds doubleValue]];
#endif	
}

////////////////////////////////////////////////////////////////////////////////////////////////
// mac addr

-(FLXMacAddr* )macaddrFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==6);
	return [FLXMacAddr macAddrWithData:[NSData dataWithBytes:theBytes length:theLength]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// point

-(NSValue* )pointFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	const Float64* theFloats = theBytes;
	NSNumber* x = [self realFromBytes:theFloats length:8];
	NSNumber* y = [self realFromBytes:(theFloats+1) length:8];
	// Note: possible loss of precision on 32 bit platforms as NSPoint uses Float32, not Float64
	return [NSValue valueWithPoint:NSMakePoint([x doubleValue],[y doubleValue])];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// time interval

-(FLXTimeInterval* )intervalFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);

#ifdef HAVE_INT64_TIMESTAMP
	// int64 interval
	// TODO: I doubt number is seconds, propably microseconds, so need to adjust
	NSNumber* interval = [self integerFromBytes:theBytes length:8];
#else
	// float8 interval 
	NSNumber* interval = [self realFromBytes:theBytes length:8];
#endif
	const UInt32* thePtr = theBytes;
	NSNumber* day = [self integerFromBytes:(thePtr + 2) length:4];
	NSNumber* month = [self integerFromBytes:(thePtr + 3) length:4];
	return [FLXTimeInterval intervalWithSeconds:interval days:day months:month];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// arrays

-(NSArray* )arrayFromBytes:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	// use 4 byte alignment
	const UInt32* thePtr = theBytes;
	// get number of dimensions - we allow zero-dimension arrays
	NSInteger dim = [[self integerFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(dim >= 0 && dim <= ARRAY_MAXDIM);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// return empty array if dim is zero
	if(dim==0) return [NSArray array];	
	// get flags - should be zero or one
	NSInteger flags = [[self integerFromBytes:(thePtr++) length:4] integerValue];
	NSParameterAssert(flags==0 || flags==1);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
	// get type of array
	FLXPostgresOid type = [[self unsignedIntegerFromBytes:(thePtr++) length:4] unsignedIntegerValue];
	NSParameterAssert(type==theType);
	NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));

	// create an array to hold tuples
	FLXPostgresArray* theArray = [FLXPostgresArray arrayWithDimensions:dim type:type];
	
	NSLog(@"data = %@",[NSData dataWithBytes:theBytes length:theLength]);
	
	// for each dimension, retrieve dimension and lower bound
	NSInteger tuples = dim ?  1 : 0;
	for(NSInteger i = 0; i < dim; i++) {
		NSInteger dimsize = [[self integerFromBytes:(thePtr++) length:4] integerValue];
		NSParameterAssert(thePtr <= (const UInt32* )((const UInt8* )theBytes + theLength));
		NSInteger bound =  [[self integerFromBytes:(thePtr++) length:4] integerValue];
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
		NSUInteger length = [[self unsignedIntegerFromBytes:(thePtr++) length:4] unsignedIntegerValue];
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
	
	return [theArray array];
}

@end

////////////////////////////////////////////////////////////////////////////////
// floxsom and jexson

/*
 -(NSString* )stringAtIndex:(NSUInteger)theIndex {
 NSArray* theType = [m_theDictionary objectForKey:[NSNumber numberWithUnsignedInteger:theIndex]];
 return theType ? [theType objectAtIndex:0] : nil;
 }
 
 -(FLXPostgresType)typeAtIndex:(NSUInteger)theIndex {
 NSArray* theType = [m_theDictionary objectForKey:[NSNumber numberWithUnsignedInteger:theIndex]];
 if(theType==nil) return FLXPostgresTypeUnknown;
 NSParameterAssert([theType isKindOfClass:[NSArray class]] && [theType count] >= 2);
 return (FLXPostgresType)[[theType objectAtIndex:1] integerValue];
 }
 
 -(NSUInteger)indexForType:(FLXPostgresType)theType {
 NSNumber* theIndex = [m_theReverseDictionary objectForKey:[NSNumber numberWithInteger:theType]];
 return ((theIndex==nil) ? 0 : [theIndex unsignedIntegerValue]);  
 }
 
 -(void)insertString:(NSString* )theType atIndex:(NSUInteger)theIndex {
 NSInteger theInternalType = FLXPostgresTypeUnknown;
 if([theType isEqual:@"bool"]) {
 theInternalType = FLXPostgresTypeBool;
 } else if([theType isEqual:@"bytea"]) {
 theInternalType = FLXPostgresTypeData;    
 } else if([theType isEqual:@"char"] || [theType isEqual:@"text"] || [theType isEqual:@"varchar"] || [theType isEqual:@"name"]) {
 theInternalType = FLXPostgresTypeString;
 } else if([theType isEqual:@"int8"] || [theType isEqual:@"int4"] || [theType isEqual:@"int2"]) {
 // int2 = smallint, int4 = integer, int8 = bigint
 theInternalType = FLXPostgresTypeInteger;    
 } else if([theType isEqual:@"float4"] || [theType isEqual:@"float8"]) {
 theInternalType = FLXPostgresTypeReal;    
 }
 [m_theDictionary setObject:[NSArray arrayWithObjects:theType,[NSNumber numberWithInteger:theInternalType],nil] forKey:[NSNumber numberWithUnsignedInteger:theIndex]];
 [m_theReverseDictionary setObject:[NSNumber numberWithUnsignedInteger:theIndex] forKey:[NSNumber numberWithInteger:theInternalType]];
 }
 */


/*
+(NSDate* )dateFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theLength==4);
	SInt32 theDate = *((SInt32* )theBytes);
	NSString* theString = [NSString stringWithUTF8String:PGTYPESdate_to_asc(theDate)];
//	NSParameterAssert([theString length]==10);
	return [NSCalendarDate dateWithString:theString calendarFormat:@"%Y-%m-%d"];
}

+(NSDate* )datetimeFromBytes:(const char* )theBytes length:(NSUInteger)theLength {
//	NSParameterAssert(theLength==4);
	SInt32 theDate = *((SInt32* )theBytes);
	NSString* theString = [NSString stringWithUTF8String:PGTYPESdate_to_asc(theDate)];
	NSLog(@"datetime = %@",theString);
	return [NSCalendarDate calendarDate];
}
*/
