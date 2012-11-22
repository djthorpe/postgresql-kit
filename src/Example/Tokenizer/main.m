
#import <Foundation/Foundation.h>
#import "PGServerHostAccess.h"
#import "PGServerConfiguration.h"

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
//		NSString* thePath = @"~/Library/Application Support/PostgreSQL/postgresql.conf";
//		PGServerConfiguration* config = [[PGServerConfiguration alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		NSString* thePath = @"~/Library/Application Support/PostgreSQL/pg_hba.conf";
		PGServerHostAccess* config = [[PGServerHostAccess alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		
		BOOL success = [config load];
		if(success==NO) {
			NSLog(@"error!");
			returnValue = -1;
		} else {
			NSLog(@"config = %@",config);
		}
		
/*		for(NSString* key in [config keys]) {
			printf("%s => %s\n",[key UTF8String],[[[config objectForKey:key] description] UTF8String]);
		}
*/	}
	
    return returnValue;
}
