
#import "PGSchemaTestApplication.h"
#import <PGSchemaKit/PGSchemaKit.h>

@implementation PGSchemaTestApplication

NSString* schemaTypes = @"schema.xml";

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSArray* resources = [[NSBundle mainBundle] pathsForResourcesOfType:schemaTypes inDirectory:nil];
	for(NSString* path in resources) {
		NSError* error = nil;
		PGSchema* schema = [PGSchema schemaWithPath:path error:&error];
		if(error) {
			NSLog(@"Error: %@: %@",[path lastPathComponent],[error localizedDescription]);
		} else {
			NSLog(@"Schema = %@",schema);
		}
	}
}

@end
