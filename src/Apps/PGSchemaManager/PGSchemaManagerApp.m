
#import "PGSchemaManagerApp.h"
#import <PGClientKit/PGClientKit.h>
#import <PGSchemaKit/PGSchemaKit.h>

@implementation PGSchemaManagerApp

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSError* error = nil;
	PGConnection* connection = [[PGConnection alloc] init];
	PGSchema* schema = [[PGSchema alloc] initWithConnection:connection name:nil];
	NSString* schemaPath = [[NSBundle mainBundle] resourcePath];
	[schema addSchemaSearchPath:schemaPath error:&error];
	if(error) {
		NSLog(@"Error: %@",[error localizedDescription]);
		return;
	}
	NSLog(@"Schema = %@",[schema schemas]);
}

@end
