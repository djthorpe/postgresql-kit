
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

@implementation PGSchemaProductOpTable

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	if(isDryrun) {
		// TODO: check to make sure table is not created
	} else {
		NSString* statement = [PGSchemaManager sqlWithFormat:@"PGSchemaProductOpTableCreate" attributes:[self attributes] error:error];
		if(statement==nil) {
			return NO;
		}
		NSLog(@"TODO: Create %@",statement);
	}
	return YES;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Update %@",self);
	return NO;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Drop %@",self);
	return NO;
}

@end
