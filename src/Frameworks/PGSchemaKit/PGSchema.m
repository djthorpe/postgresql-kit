
#import "PGSchemaKit.h"

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
typedef enum {
	PGSchemaErrorMissingDTD = 100,
	PGSchemaErrorParse = 101
} PGSchemaErrorType;

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

-(NSError* )_errorWithCode:(PGSchemaErrorType)code description:(NSString* )description path:(NSString* )path {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSString* reason = nil;
	switch(code) {
		case PGSchemaErrorMissingDTD:
			reason = @"Missing or invalid DTD";
			break;
		case PGSchemaErrorParse:
			reason = @"Schema Parse Error";
			break;
		default:
			reason = @"Unknown error";
			break;
	}
	if(path) {
		[dictionary setObject:path forKey:NSFilePathErrorKey];
	}
	if(description) {
		[dictionary setObject:[NSString stringWithFormat:@"%@: %@",reason,description] forKey:NSLocalizedDescriptionKey];
	} else {
		[dictionary setObject:reason forKey:NSLocalizedDescriptionKey];
	}
	return [NSError errorWithDomain:PGSchemaErrorDomain code:code userInfo:dictionary];
}

-(NSXMLDTD* )_dtdWithError:(NSError** )error {
	NSString* path = [[NSBundle mainBundle] pathForResource:@"pgschema" ofType:@"dtd"];
	if(path==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorMissingDTD description:nil path:nil];
		return nil;
	}
	NSError* xmlerror = nil;
	NSXMLDTD* dtd = [[NSXMLDTD alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:0 error:&xmlerror];
	if(xmlerror) {
		(*error) = [self _errorWithCode:PGSchemaErrorMissingDTD description:[xmlerror localizedDescription] path:nil];
		return nil;
	}
	return dtd;
}

-(BOOL)_readSchemaWithPath:(NSString* )path error:(NSError** )error {
	NSURL* url = [NSURL fileURLWithPath:path];
	NSError* xmlerror = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&xmlerror];
	if(document==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[xmlerror localizedDescription] path:path];
		return NO;
	}
	// TODO: extract parts
	return YES;
}


@end


