
#import <Foundation/Foundation.h>
#import "PGServerHostAccess.h"

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		NSString* thePath = @"~/Library/Application Support/PostgreSQL/pg_hba.conf";
		PGServerHostAccess* config = [[PGServerHostAccess alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		NSLog(@"config = %@",config);
		
/*		for(NSString* key in [config keys]) {
			printf("%s => %s\n",[key UTF8String],[[[config objectForKey:key] description] UTF8String]);
		}
*/	}
	
    return returnValue;
}
