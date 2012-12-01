
#import <Foundation/Foundation.h>
#import <PGServerKit/PGServerKit.h>

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
//		NSString* thePath = @"~/Library/Application Support/PostgreSQL/postgresql.conf";
//		PGServerConfiguration* config = [[PGServerConfiguration alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
//		NSString* thePath = @"~/Library/Application Support/PostgreSQL/pg_hba.conf";
		NSString* thePath = @"~/pg_hba.conf";
		PGServerHostAccess* config = [[PGServerHostAccess alloc] initWithPath:[thePath stringByExpandingTildeInPath]];
		BOOL success = [config load];
		if(success==NO) {
			NSLog(@"error!");
			returnValue = -1;
		} else {
			for(PGServerHostAccessRule* rule in [config rules]) {
				printf("rule => %s\n",[[rule description] UTF8String]);
			}
		}
	}
	
    return returnValue;
}
