
#import "PGSchemaKit.h"

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchema

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)initWithPath:(NSString* )path error:(NSError** )error {
	self = [super init];
	if(self) {
		// read in the statements
	}
	return self;
}

+(PGSchema* )schemaWithPath:(NSString* )path error:(NSError** )error {
	return [[PGSchema alloc] initWithPath:path error:error];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(BOOL)_readSchemaWithPath:(NSString* )path error:(NSError** )error {
	NSURL* url = [NSURL fileURLWithPath:path];
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:error];
	if(document==nil) {
		return NO;
	}
	return YES;
}


@end


