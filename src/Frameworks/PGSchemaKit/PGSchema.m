
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
NSString* PGSchemaFileExtension = @".schema.xml";

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchema

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithConnection:(PGConnection* )connection name:(NSString* )name {
	self = [super init];
	if(self) {
		NSParameterAssert(connection);
		_connection = connection;
		_name = name;
		_searchpath = [NSMutableArray array];
		[_searchpath addObject:[[NSBundle mainBundle] resourcePath]];
		_schemas = [NSArray array];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)addSchemaSearchPath:(NSString* )path error:(NSError** )error {
	NSParameterAssert(path);
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]==NO || isDirectory==NO) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorSearchPath description:@"Invalid search path" path:path];
		return NO;
	}
	[_searchpath addObject:path];
	NSMutableArray* schemas = [NSMutableArray array];
	for(NSString* path in _searchpath) {
		NSArray* products = [self _scanForSchemasAtPath:path recursive:NO error:error];
		if(products==nil) {
			[_searchpath removeObject:path];
			return NO;
		}
		[schemas addObjectsFromArray:products];
	}
	_schemas = schemas;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods


+(NSError* )errorWithCode:(PGSchemaErrorType)code description:(NSString* )description path:(NSString* )path {
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

-(NSArray* )_scanForSchemasAtPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error {
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString* filename = nil;
	NSMutableArray* schemas = [NSMutableArray array];
	while(filename = [enumerator nextObject]) {
		if([filename hasPrefix:@"."]) {
			continue;
		}
		NSString* filepath = [path stringByAppendingPathComponent:filename];
		BOOL isDirectory = NO;
		if([filename hasSuffix:PGSchemaFileExtension]) {
			PGSchemaProduct* schemaproduct = [PGSchemaProduct schemaWithPath:filepath error:error];
			if(schemaproduct==nil) {
				return nil;
			}
			[schemas addObject:schemaproduct];
			continue;
		}
		if([[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDirectory]==YES && isDirectory==YES) {
			if(isRecursive) {
				NSArray* subschemas = [self _scanForSchemasAtPath:filepath recursive:isRecursive error:error];
				if(subschemas==nil) {
					return nil;
				}
				[schemas addObjectsFromArray:subschemas];
			}
		}
	}				
	return schemas;
}

@end
