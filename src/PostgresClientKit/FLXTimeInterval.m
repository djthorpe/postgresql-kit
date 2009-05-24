
#import "FLXTimeInterval.h"

@implementation FLXTimeInterval

@synthesize seconds;
@synthesize days;
@synthesize months;

////////////////////////////////////////////////////////////////////////////////
// Constructor

+(FLXTimeInterval* )interval {
	return [[[FLXTimeInterval alloc] init] autorelease];
}

+(FLXTimeInterval* )intervalWithSeconds:(NSTimeInterval)theSeconds days:(NSInteger)days months:(NSInteger)months {
	FLXTimeInterval* theObject = [self interval];
	[theObject setSeconds:theSeconds];
	[theObject setDays:days];
	[theObject setMonths:months];	
	return theObject;
}

////////////////////////////////////////////////////////////////////////////////
// NSCopying

-(id)copyWithZone:(NSZone* )zone {
	FLXTimeInterval* otherObject = [[FLXTimeInterval allocWithZone:zone] init];
	[otherObject setSeconds:[self seconds]];
	[otherObject setDays:[self days]];
	[otherObject setMonths:[self months]];
	return otherObject;
}

////////////////////////////////////////////////////////////////////////////////

-(NSString* )stringValue {
	NSString* secondsPart = [self seconds] ? [NSString stringWithFormat:@"%g secs ",[self seconds]] : @"";
	NSString* daysPart = [self days] ? [NSString stringWithFormat:@"%d days ",[self days]] : @"";
	NSString* monthsPart = [self months] ? [NSString stringWithFormat:@"%d months ",[self months]] : @"";
	return [[NSString stringWithFormat:@"%@%@%@",secondsPart,daysPart,monthsPart] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

////////////////////////////////////////////////////////////////////////////////
// NSObject

-(NSString* )description {
	return [NSString stringWithFormat:@"<FLXTimeInterval %@>",[self stringValue]];
}

-(BOOL)isEqual:(id)anObject {
	if([anObject isKindOfClass:[FLXTimeInterval class]]==NO) return NO;
	if([anObject seconds] != [self seconds]) return NO;
	if([anObject days] != [self days]) return NO;
	if([anObject months] != [self months]) return NO;
	return YES;
}

@end
