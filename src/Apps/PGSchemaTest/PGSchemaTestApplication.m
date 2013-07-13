
#import "PGSchemaTestApplication.h"
#import <PGSchemaKit/PGSchemaKit.h>

@implementation PGSchemaTestApplication

NSString* schemaTypes = @"schema.xml";

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSArray* resources = [[NSBundle mainBundle] pathsForResourcesOfType:schemaTypes inDirectory:nil];
	NSLog(@"app started, load schema = %@",resources);
}

@end
