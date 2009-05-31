
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"
#import "FLXPostgresTypes+DateTime.h"
#import "FLXPostgresTypes+NSNumber.h"

@implementation FLXPostgresTypes (DateTime)

// number of microseconds per second
#define USECS_PER_SEC ((double)1000000)

////////////////////////////////////////////////////////////////////////////////////////////////
// return epoch

-(NSCalendarDate* )_epochDate {
	return [NSCalendarDate dateWithYear:2000 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// time interval

-(NSObject* )boundValueFromInterval:(FLXTimeInterval* )theInterval type:(FLXPostgresOid* )theTypeOid {
	NSParameterAssert(theInterval);
	(*theTypeOid) = FLXPostgresTypeInterval;	
	// data = <8 bytes integer or 8 bytes real>
	// then 4 bytes day
	// then 4 bytes month
	NSMutableData* theData = [NSMutableData dataWithCapacity:16];
	NSParameterAssert(theData);
	if([self isIntegerTimestamp]) {
		[theData appendData:[self boundDataFromInt64:(long long)([theInterval seconds] * USECS_PER_SEC)]];
	} else {
		[theData appendData:[self boundDataFromFloat64:[theInterval seconds]]];
	}
	[theData appendData:[self boundDataFromInt32:[theInterval days]]];
	[theData appendData:[self boundDataFromInt32:[theInterval months]]];
	return theData;
}

-(FLXTimeInterval* )intervalFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==16);
	NSNumber* interval= nil;
	if([self isIntegerTimestamp]) {
		// int64 interval
		// TODO: I doubt number is seconds, propably microseconds, so need to adjust
		interval = [self integerObjectFromBytes:theBytes length:8];
	} else {
		// float8 interval 
		interval = [self realObjectFromBytes:theBytes length:8];
	}
	const UInt32* thePtr = theBytes;
	NSNumber* day = [self integerObjectFromBytes:(thePtr + 2) length:4];
	NSNumber* month = [self integerObjectFromBytes:(thePtr + 3) length:4];
	return [FLXTimeInterval intervalWithSeconds:[interval doubleValue] days:[day integerValue] months:[month integerValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// abstime

-(NSDate* )abstimeFromBytes:(const void* )theBytes length:(NSUInteger)theLength {	
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// convert bytes into integer
	NSNumber* theTime = [self integerObjectFromBytes:theBytes length:theLength];
	return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[theTime doubleValue]];
}

////////////////////////////////////////////////////////////////////////////////////////////////
// date

-(NSDate* )dateFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==4);
	// this is number of days since 1st January 2000
	NSNumber* theDays = [self integerObjectFromBytes:theBytes length:theLength];
	NSCalendarDate* theDate = [[self _epochDate] dateByAddingYears:0 months:0 days:[theDays integerValue] hours:0 minutes:0 seconds:0];	
	[theDate setCalendarFormat:@"%Y-%m-%d"];
	return theDate;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// timestamp

-(NSDate* )timestampFromBytes:(const void* )theBytes length:(NSUInteger)theLength {
	NSParameterAssert(theBytes);
	NSParameterAssert(theLength==8);
	if([self isIntegerTimestamp]) {
		// this is number of microseconds since 1st January 2000
		NSNumber* theMicroseconds = [self integerObjectFromBytes:theBytes length:theLength];	
		return [[self _epochDate] addTimeInterval:([theMicroseconds doubleValue] / (double)USECS_PER_SEC)];
	} else {
		double theSeconds = [self float64FromBytes:theBytes];	
		return [[self _epochDate] addTimeInterval:theSeconds];
	}
}

@end
