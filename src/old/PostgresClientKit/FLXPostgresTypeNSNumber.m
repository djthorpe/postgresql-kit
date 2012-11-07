#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypeNSNumber.h"

////////////////////////////////////////////////////////////////////////////////

FLXPostgresOid FLXPostgresTypeNSNumberTypes[] = { 
	FLXPostgresOidInt8,FLXPostgresOidInt2,FLXPostgresOidInt4,
	FLXPostgresOidFloat4,FLXPostgresOidFloat8,FLXPostgresOidBool,0 
};

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresTypeNSNumber

-(id)initWithConnection:(FLXPostgresConnection* )theConnection {
	NSParameterAssert(theConnection);
	self = [super init];
	if(self != nil) {
		m_theConnection = [theConnection retain];
	}
	return self;
}

-(void)dealloc {
	[m_theConnection release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

-(FLXPostgresOid* )remoteTypes {
	return FLXPostgresTypeNSNumberTypes;
}

-(Class)nativeClass {
	return [NSNumber class];
}

////////////////////////////////////////////////////////////////////////////////
// integer and unsigned integer

-(SInt16)int16FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((SInt16* )theBytes);
#else
	return EndianS16_BtoN(*((SInt16* )theBytes));
#endif
}

-(SInt32)int32FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((SInt32* )theBytes);
#else
	return EndianS32_BtoN(*((SInt32* )theBytes));
#endif	
}

-(SInt64)int64FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((SInt64* )theBytes);
#else
	return EndianS64_BtoN(*((SInt64* )theBytes));
#endif		
}

-(UInt16)unsignedInt16FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((UInt16* )theBytes);
#else
	return EndianU16_BtoN(*((UInt16* )theBytes));
#endif		
}

-(UInt32)unsignedInt32FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((UInt32* )theBytes);
#else
	return EndianU32_BtoN(*((UInt32* )theBytes));
#endif		
}

-(UInt64)unsignedInt64FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((UInt64* )theBytes);
#else
	return EndianU64_BtoN(*((UInt64* )theBytes));
#endif		
}

-(NSNumber* )integerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==2 || theLength==4 || theLength==8);
	switch(theLength) {
		case 2:
			return [NSNumber numberWithShort:[self int16FromBytes:theBytes]];
		case 4:
			return [NSNumber numberWithInteger:[self int32FromBytes:theBytes]];
		case 8:
			return [NSNumber numberWithLongLong:[self int64FromBytes:theBytes]];
	}
	return nil;
}

-(NSNumber* )unsignedIntegerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==2 || theLength==4 || theLength==8);
	switch(theLength) {
		case 2:
			return [NSNumber numberWithUnsignedShort:[self unsignedInt16FromBytes:theBytes]];
		case 4:
			return [NSNumber numberWithUnsignedInteger:[self unsignedInt32FromBytes:theBytes]];
		case 8:
			return [NSNumber numberWithUnsignedLongLong:[self unsignedInt64FromBytes:theBytes]];
	}
	return nil;
}

-(NSData* )remoteDataFromInt64:(SInt64)theValue {
	NSParameterAssert(sizeof(SInt64)==8);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue = EndianS64_NtoB(theValue);
#endif	
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

-(NSData* )remoteDataFromInt32:(SInt32)theValue {
	NSParameterAssert(sizeof(SInt32)==4);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue = EndianS32_NtoB(theValue);
#endif	
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

-(NSData* )remoteDataFromInt16:(SInt16)theValue {
	NSParameterAssert(sizeof(SInt16)==2);
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	theValue = EndianS16_NtoB(theValue);
#endif	
	return [NSData dataWithBytes:&theValue length:sizeof(theValue)];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// real (floating point numbers)

-(Float32)float32FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((Float32* )theBytes);
#else
    union { Float32 r; UInt32 i; } u32;
	u32.r = *((Float32* )theBytes);		
	u32.i = CFSwapInt32HostToBig(u32.i);			
	return u32.r;
#endif		
}

-(Float64)float64FromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
#if defined(__ppc__) || defined(__ppc64__)
	return *((Float64* )theBytes);
#else
    union { Float64 r; UInt64 i; } u64;
	u64.r = *((Float64* )theBytes);		
	u64.i = CFSwapInt64HostToBig(u64.i);			
	return u64.r;
#endif		
}

-(NSNumber* )realObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theLength==4 || theLength==8);
	switch(theLength) {
		case 4:
			return [NSNumber numberWithFloat:[self float32FromBytes:theBytes]];
		case 8:
			return [NSNumber numberWithDouble:[self float64FromBytes:theBytes]];
	}
	return nil;
}


-(NSData* )remoteDataFromFloat32:(Float32)theValue {
	NSParameterAssert(sizeof(Float32)==4);
	union { Float32 r; UInt32 i; } u32;
	u32.r = theValue;
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	u32.i = CFSwapInt32HostToBig(u32.i);			
#endif
	NSData* theData = [NSData dataWithBytes:&u32 length:sizeof(u32)];	
	return theData;
}

-(NSData* )remoteDataFromFloat64:(Float64)theValue {
	NSParameterAssert(sizeof(Float64)==8);
	union { Float64 r; UInt64 i; } u64;
	u64.r = theValue;
#if defined(__ppc__) || defined(__ppc64__)
	// don't swap
#else
	u64.i = CFSwapInt64HostToBig(u64.i);			
#endif
	NSData* theData = [NSData dataWithBytes:&u64 length:sizeof(u64)];	
	return theData;
}


////////////////////////////////////////////////////////////////////////////////////////////////
// boolean

-(BOOL)booleanFromBytes:(const void* )theBytes {
	NSParameterAssert(theBytes);
	return (*((const int8_t* )theBytes) ? YES : NO);
}

-(NSNumber* )booleanObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==1);
	return [NSNumber numberWithBool:[self booleanFromBytes:theBytes]];
}


-(NSData* )remoteDataFromBoolean:(BOOL)theValue {
	return [NSData dataWithBytes:&theValue length:1];
}


////////////////////////////////////////////////////////////////////////////////
// protocol implementation

-(NSData* )remoteDataFromObject:(id)theObject type:(FLXPostgresOid* )theType {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSNumber class]]);	
	NSParameterAssert(theType);	
	const char* type = [(NSNumber* )theObject objCType];
	switch(type[0]) {
		case 'c':
		case 'C':
		case 'B': // boolean
			(*theType) = FLXPostgresOidBool;
			return [self remoteDataFromBoolean:[(NSNumber* )theObject boolValue]];
		case 'i': // integer
		case 'l': // long
		case 'S': // unsigned short
			(*theType) = FLXPostgresOidInt4;
			return [self remoteDataFromInt32:[(NSNumber* )theObject shortValue]];
		case 's':
			(*theType) = FLXPostgresOidInt2;
			return [self remoteDataFromInt16:[(NSNumber* )theObject shortValue]];
		case 'q': // long long
		case 'Q': // unsigned long long
		case 'I': // unsigned integer
		case 'L': // unsigned long
			(*theType) = FLXPostgresOidInt8;
			return [self remoteDataFromInt64:[(NSNumber* )theObject longLongValue]];
		case 'f': // float
			(*theType) = FLXPostgresOidFloat4;
			return [self remoteDataFromFloat32:[(NSNumber* )theObject floatValue]];
		case 'd': // double
			(*theType) = FLXPostgresOidFloat8;
			return [self remoteDataFromFloat64:[(NSNumber* )theObject doubleValue]];
		default:
			// we shouldn't get here
			NSParameterAssert(NO);
	}
	
	// we shouldn't reach here
	return nil;
}

-(id)objectFromRemoteData:(const void* )theBytes length:(NSUInteger)theLength type:(FLXPostgresOid)theType {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength);
	NSParameterAssert(theType);
	switch(theType) {
		case FLXPostgresOidInt8:
		case FLXPostgresOidInt2:
		case FLXPostgresOidInt4:
			return [self integerObjectFromBytes:theBytes length:theLength];
		case FLXPostgresOidFloat4:
		case FLXPostgresOidFloat8:
			return [self realObjectFromBytes:theBytes length:theLength];
		case FLXPostgresOidBool:
			return [self booleanObjectFromBytes:theBytes length:theLength];
		default:
			return nil;
	}	
}

-(NSString* )quotedStringFromObject:(id)theObject {
	NSParameterAssert(theObject);
	NSParameterAssert([theObject isKindOfClass:[NSNumber class]]);
	NSParameterAssert(theObject);
	const char* type = [theObject objCType];
	if(type[0]=='c' || type[0]=='C' || type[0]=='B') {
		return ([(NSNumber* )theObject boolValue] ? @"true" : @"false");
	} else {
		return [(NSNumber* )theObject stringValue];
	}
}

@end
