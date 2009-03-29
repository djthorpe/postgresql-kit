
#import "Name.h"

@implementation Name

+(NSString* )tableName {
	return @"name";
}

+(NSArray* )tableColumns {
	return [NSArray arrayWithObjects:@"name",nil];
}

@end
