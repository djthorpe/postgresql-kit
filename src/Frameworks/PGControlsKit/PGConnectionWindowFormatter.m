
#import "PGConnectionWindowFormatter.h"

@implementation PGConnectionWindowFormatter

-(void)awakeFromNib {
	if(!_cs) {
		_cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	}
}

-(NSNumber* )numericValueForString:(NSString* )string {
	NSParameterAssert(_cs);
	if([string length]==0) {
		return nil;
	}
	NSString* string2 = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSRange range = [string2 rangeOfCharacterFromSet:_cs];
	if(range.location != NSNotFound) {
		return nil;
	}
	return [NSDecimalNumber decimalNumberWithString:string];
}


-(NSString* )stringForObjectValue:(id)anObject {
	return [NSString stringWithFormat:@"%@",anObject];
}

-(BOOL)getObjectValue:(id* )anObject forString:(NSString* )string errorDescription:(NSString** )anError {
	NSParameterAssert(anObject);
	NSParameterAssert(string);
	BOOL returnValue = YES;
	NSNumber* port = [self numericValueForString:string];
	NSString* error = nil;
	if(port==nil) {
		error = @"Invalid value";
		returnValue = NO;
	} else {
		*anObject = port;
	}
	if(anError) {
		*anError = error;
	}
	return returnValue;
}
@end
