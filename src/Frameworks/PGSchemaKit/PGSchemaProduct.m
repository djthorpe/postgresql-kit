
#import "PGSchemaKit.h"
#import "PGSchemaProductNV.h"
#import "PGSchemaProductOp.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaRootNode = @"product";

////////////////////////////////////////////////////////////////////////////////
// private method declarations

@interface PGSchemaProduct (Private)
-(BOOL)_initWithPath:(NSString* )path error:(NSError** )error;
@end

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaProduct

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	return nil;
}

-(id)initWithPath:(NSString* )path error:(NSError** )error {
	self = [super init];
	if(self) {
		_productnv = nil;
		_requires = nil;
		if([self _initWithPath:path error:error]==NO) {
			return nil;
		}
	}
	return self;
}

+(PGSchemaProduct* )schemaWithPath:(NSString* )path error:(NSError** )error {
	return [[PGSchemaProduct alloc] initWithPath:path error:error];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic name,version;

-(NSString* )name {
	return [(PGSchemaProductNV* )_productnv name];
}

-(NSUInteger)version {
	return [(PGSchemaProductNV* )_productnv version];
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

-(NSXMLDTD* )_dtdWithError:(NSError** )error rootName:(NSString* )rootName {
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
	[dtd setName:rootName];
	return dtd;
}

-(NSXMLDocument* )_schemaDocumentWithPath:(NSString* )path error:(NSError** )error {
	NSURL* url = [NSURL fileURLWithPath:path];
	NSError* xmlerror = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentValidate error:&xmlerror];
	if(document==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[xmlerror localizedDescription] path:path];
		return nil;
	}
	// read DTD
	NSXMLDTD* dtd = [self _dtdWithError:error rootName:PGSchemaRootNode];
	if(dtd==nil) {
		return nil;
	}
	// validate document against DTD
	[document setDTD:dtd];
	if([document validateAndReturnError:&xmlerror]==NO) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[xmlerror localizedDescription] path:path];
		return nil;
	}
	
	// success
	return document;
}

-(BOOL)_initWithPath:(NSString* )path error:(NSError** )error {
	NSParameterAssert(path);
	NSError* localerror = nil;
	NSXMLDocument* document = [self _schemaDocumentWithPath:path error:error];
	NSXMLElement* rootNode = [document rootElement];
	if(document==nil) {
		return NO;
	}
	NSParameterAssert(rootNode);

	_productnv = [[PGSchemaProductNV alloc] initWithXMLNode:rootNode];
	if(_productnv==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:@"invalid name or version on <product> element" path:path];
		return NO;
	}
	
	// get requires statements
	NSArray* requires = [document nodesForXPath:@"//requires" error:&localerror];
	if(requires==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_requires = [NSMutableArray arrayWithCapacity:[requires count]];
	for(NSXMLElement* node in requires) {
		PGSchemaProductNV* productnv = [[PGSchemaProductNV alloc] initWithXMLNode:node];
		if(productnv==nil) {
			(*error) = [self _errorWithCode:PGSchemaErrorParse description:@"invalid name or version on <requires> element" path:path];
			return NO;
		}
		[_requires addObject:productnv];
	}
	
	// create statements
	NSArray* create = [document nodesForXPath:@"//create/*" error:&localerror];
	if(create==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_create = [NSMutableArray arrayWithCapacity:[create count]];
	for(NSXMLElement* node in create) {
		PGSchemaProductOp* op = [[PGSchemaProductOp alloc] initWithXMLNode:node];
		if(op==nil) {
			(*error) = [self _errorWithCode:PGSchemaErrorParse description:@"invalid operation on <create> element" path:path];
			return NO;
		}
		[_create addObject:op];
	}
	
	// drop statements
	NSArray* drop = [document nodesForXPath:@"//drop/*" error:&localerror];
	if(drop==nil) {
		(*error) = [self _errorWithCode:PGSchemaErrorParse description:[localerror localizedDescription] path:path];
		return NO;
	}
	_drop = [NSMutableArray arrayWithCapacity:[drop count]];
	for(NSXMLElement* node in drop) {
		PGSchemaProductOp* op = [[PGSchemaProductOp alloc] initWithXMLNode:node];
		if(op==nil) {
			(*error) = [self _errorWithCode:PGSchemaErrorParse description:@"invalid operation on <drop> element" path:path];
			return NO;
		}
		[_drop addObject:op];
	}
	
	return YES;
}


////////////////////////////////////////////////////////////////////////////////
// description

-(NSString* )description {
	return [NSString stringWithFormat:@"<%@ name=\"%@\" version=\"%lu\" requires=%@ create=%@ drop=%@>",NSStringFromClass([self class]),[self name],[self version],
				_requires,_create,_drop];
}

@end


