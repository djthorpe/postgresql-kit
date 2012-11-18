
#import <Foundation/Foundation.h>
#import "PGServerConfiguration.h"

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		NSString* thePath = @"~/Library/Application Support/PostgreSQL/postgresql.conf";
		PGServerConfiguration* config = [[PGServerConfiguration alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		
		for(NSString* key in [config keys]) {
			printf("%s => %s\n",[key UTF8String],[[[config objectForKey:key] description] UTF8String]);
		}
	}
	
    return returnValue;
}
