
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+NSNumber.h"

@implementation FLXPostgresTypes (NSNumber)

////////////////////////////////////////////////////////////////////////////////////////////////
// integer and unsigned integer

-(NSNumber* )integerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
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


-(NSNumber* )unsignedIntegerObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
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

-(Float32)floatFromBytes:(const void* )theBytes {
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

-(Float64)doubleFromBytes:(const void* )theBytes {
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
			return [NSNumber numberWithFloat:[self floatFromBytes:theBytes]];
		case 8:
			return [NSNumber numberWithDouble:[self doubleFromBytes:theBytes]];
	}
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// boolean

-(NSNumber* )booleanObjectFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==1);
	return [NSNumber numberWithBool:(*((const int8_t* )theBytes) ? YES : NO)];	
}

@end
