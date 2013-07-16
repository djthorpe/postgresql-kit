
#import "PGSchemaTestApplication.h"
#import <PGClientKit/PGClientKit.h>
#import <PGSchemaKit/PGSchemaKit.h>

@implementation PGSchemaTestApplication

NSString* schemaTypes = @"schema.xml";

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSError* error = nil;
	PGConnection* connection = [[PGConnection alloc] init];
	PGSchema* schema = [[PGSchema alloc] initWithConnection:connection name:nil];
	[schema addSchemaPath:[[NSBundle mainBundle] resourcePath] error:&error];
	if(error) {
		NSLog(@"Error: %@",[error localizedDescription]);
		return;
	}
	NSLog(@"Schema = %@",[schema schemas]);
}

@end
