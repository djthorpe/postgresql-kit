
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

@implementation PGSchemaProductOpTable

-(BOOL)createWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithDictionary:[self attributes]];
	[attr setObject:[self cdata] forKey:@"cdata"];
	[attr setObject:[self name] forKey:@"name"];
	NSString* statement = [PGSchemaManager formatSQL:@"PGSchemaProductOpTableCreate" attributes:[self attributes]];
	NSLog(@"TODO: Create %@",statement);
	return YES;
}

-(BOOL)updateWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Update %@ with %@",[self name],[self cdata]);	
	return NO;
}

-(BOOL)dropWithConnection:(PGConnection* )connection dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSLog(@"TODO: Drop %@ with %@",[self name],[self cdata]);
	return NO;
}

@end
