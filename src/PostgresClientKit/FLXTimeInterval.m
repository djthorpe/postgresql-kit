
#import "FLXTimeInterval.h"

@implementation FLXTimeInterval

@synthesize seconds;
@synthesize days;
@synthesize months;

+(FLXTimeInterval* )intervalWithSeconds:(NSNumber* )theSeconds days:(NSNumber* )theDays months:(NSNumber* )theMonths {
	FLXTimeInterval* theObject = [[[FLXTimeInterval alloc] init] autorelease];
	[theObject setSeconds:[theSeconds doubleValue]];
	[theObject setDays:[theDays integerValue]];
	[theObject setMonths:[theMonths integerValue]];	
	return theObject;
}

-(NSString* )stringValue {
	NSString* secondsPart = [self seconds] ? [NSString stringWithFormat:@"%g secs ",[self seconds]] : @"";
	NSString* daysPart = [self days] ? [NSString stringWithFormat:@"%d days ",[self days]] : @"";
	NSString* monthsPart = [self months] ? [NSString stringWithFormat:@"%d months ",[self months]] : @"";
	return [[NSString stringWithFormat:@"%@%@%@",secondsPart,daysPart,monthsPart] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString* )description {
	return [self stringValue];
}

@end
