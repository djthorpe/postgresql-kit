
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

@implementation PGSchemaProductOpTable

-(BOOL)executeWithConnection:(PGConnection* )connection type:(PGSchemaProductOpType)type dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSParameterAssert(connection);
	switch(type) {
		case PGSchemaProductOpCreate:
			NSLog(@"TODO: create table %@",[self name]);
			return YES;
		case PGSchemaProductOpUpdate:
			NSLog(@"TODO: update table %@",[self name]);
			return YES;
		case PGSchemaProductOpDrop:
			NSLog(@"TODO: drop table %@",[self name]);
			return YES;
		default:
			(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorInternal description:@"executeWithConnection not implemented"];
			return NO;
	}
}

@end
