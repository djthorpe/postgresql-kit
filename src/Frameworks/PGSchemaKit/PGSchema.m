
#import "PGSchemaKit.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
NSString* PGSchemaFileExtension = @"schema.xml";

////////////////////////////////////////////////////////////////////////////////

@interface PGSchema (Private)

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
		_schemas = nil;
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////
// public methods

-(BOOL)addSchemaPath:(NSString* )schemaPath recursive:(BOOL)isRecursive error:(NSError** )error {
	if([_searchpath containsObject:schemaPath]==NO) {
		BOOL 
		
	}
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
		if([[filename pathExtension] isEqualToString:PGSchemaFileExtension]) {
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
