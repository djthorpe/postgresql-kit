
#import "PGSchemaKit.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
NSString* PGSchemaFileExtension = @".schema.xml";

////////////////////////////////////////////////////////////////////////////////

@interface PGSchema (Private)
-(NSArray* )_scanForSchemasAtPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;
@end

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

-(BOOL)addSearchPath:(NSString* )schemaPath error:(NSError** )error {
	NSParameterAssert(schemaPath);
	[_searchpath addObject:schemaPath];
	NSMutableArray* schemas = [NSMutableArray array];
	for(NSString* path in _searchpath) {
		NSArray* products = [self _scanForSchemasAtPath:path recursive:NO error:error];
		if(products==nil) {
			[_searchpath removeObject:schemaPath];
			return NO;
		}
		[schemas addObjectsFromArray:products];
	}
	_schemas = schemas;
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

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
