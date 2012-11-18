
#import <Foundation/Foundation.h>
#import "PGServerConfiguration.h"

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		NSString* thePath = @"~/Library/Application Support/PostgreSQL/postgresql.conf";
		PGServerConfiguration* config = [[PGServerConfiguration alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		
		for(NSString* line in [config lines]) {
			printf("%s\n",[[line description] UTF8String]);
		}
	}
	
    return returnValue;
}
