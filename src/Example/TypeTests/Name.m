
#import "Name.h"

@implementation Name

@dynamic id;
@dynamic name;
@dynamic email;
@dynamic male;

+(NSString* )tableName {
	return @"name";
}

@end
