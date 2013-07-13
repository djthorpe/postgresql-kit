
#import "PGSchemaKit.h"

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";

////////////////////////////////////////////////////////////////////////////////
// private method declarations

@interface PGSchema (Private)
-(BOOL)_readSchemaWithPath:(NSString* )path error:(NSError** )error;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchema

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path error:(NSError** )error {
	self = [super init];
	if(self) {
		if([self _readSchemaWithPath:path error:error]==NO) {
			return nil;
		}
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
	// validate against DTD
	// extract parts
	return YES;
}


@end


