
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

@implementation PGSchemaProductOpTable

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSString* statement = [PGSchemaManager formatSQL:@"PGSchemaProductOpTableCreate" attributes:[self attributes]];
	NSLog(@"TODO: Create %@",statement);
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
