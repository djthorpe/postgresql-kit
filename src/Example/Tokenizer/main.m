
/*
 This example shows how to use the PGServerKit to create a server, as
 a foundation shell tool. When the server is started, any signal (TERM or KILL)
 is handled to stop the server gracefully.
 */

#import <Foundation/Foundation.h>
#import <PGServerKit/PGServerKit.h>

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	
	@autoreleasepool {
		NSString* thePath = @"/Users/davidthorpe/Library/Application Support/PostgreSQL/postgresql.conf";
		PGServerPreferences* thePreferences = [[PGServerPreferences alloc] initWithConfigurationFile:thePath];
		NSLog(@"Preferences = %@",thePreferences);
	}
	
    return returnValue;
}
