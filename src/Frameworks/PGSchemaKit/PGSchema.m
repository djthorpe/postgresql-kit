
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
NSString* PGSchemaFileExtension = @".schema.xml";
NSString* PGSchemaName = @"postgreskit";
NSString* PGSchemaTable = @"t_product";

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
		_bundle = [NSBundle bundleForClass:[self class]];
		_searchpath = [NSMutableArray array];
		_products = [NSMutableDictionary dictionary];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic products;
@synthesize connection = _connection;

-(NSArray* )products {
	return [_products allValues];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

+(NSArray* )defaultSearchPath {
	NSBundle* thisBundle = [NSBundle bundleForClass:[self class]];
	return [NSArray arrayWithObject:[thisBundle resourcePath]];
}

-(BOOL)addSearchPath:(NSString* )path error:(NSError** )error {
	return [self addSearchPath:path recursive:NO error:error];
}

-(BOOL)addSearchPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error {
	NSParameterAssert(path);
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]==NO || isDirectory==NO) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorSearchPath description:@"Invalid search path" path:path];
		return NO;
	}
	
	// add default search path
	if([_searchpath count]==0) {
		for(NSString* path in [PGSchema defaultSearchPath]) {
			[self _addSearchPath:path];
		}
	}

	// add paths to the search path
	[self _addSearchPath:path];
	if(isRecursive) {
		for(NSString* subpath in [self _subpathsAtPath:path]) {
			[self _addSearchPath:subpath];
		}
	}
	
	// add products
	for(NSString* path in _searchpath) {
		NSArray* products = [self _productsAtPath:path error:error];
		if(products==nil) {
			[_searchpath removeObject:path];
			return NO;
		} else {
			for(PGSchemaProduct* product in products) {
				[_products setObject:product forKey:[product key]];
			}
		}
		
	}
	return YES;
}

-(BOOL)create:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSParameterAssert(product);
	// check to make sure product is in list of available products
	if([_products objectForKey:[product key]]==nil) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorDependency description:@"Schema product not found" path:nil];
		return NO;		
	}
	// check to make sure product is not already installed
	BOOL isInstalled = [self _hasProductInstalled:product error:error];
	if(*error) {
		return NO;
	}
	if(isInstalled) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorDependency description:@"Already installed" path:nil];
		return NO;		
	}
	// check each 'requires' and install these recursively
	for(PGSchemaProductNV* require in [product requires]) {
		NSLog(@"Check requires: %@",require);
	}
	
	// install product
	return YES;
}

-(BOOL)drop:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSParameterAssert(product);
	// check to make sure product is in list of available products
	// check to make sure product is already installed
	// make sure no other installed product depends on this one
	// drop product
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(NSString* )_sqlfor:(NSString* )key {
	NSParameterAssert(key);
	return NSLocalizedStringFromTableInBundle(key,@"PGSchemaKitSQL",_bundle,@"");
}

-(BOOL)_addSearchPath:(NSString* )path {
	if([_searchpath containsObject:path]==NO) {
		[_searchpath addObject:path];
		return YES;
	} else {
		return NO;
	}
}

-(NSArray* )_subpathsAtPath:(NSString* )path {
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString* filename = nil;
	NSMutableArray* paths = [NSMutableArray array];
	while(filename = [enumerator nextObject]) {
		NSString* filepath = [path stringByAppendingPathComponent:filename];
		if([filename hasPrefix:@"."]) {
			// check for hidden or special
			continue;
		}
		if([[NSFileManager defaultManager] isReadableFileAtPath:filepath]==NO) {
			// check for non-readable
			continue;
		}
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDirectory]==YES && isDirectory==YES) {
			// needs to be a directory
			NSArray* subpaths = [self _subpathsAtPath:filepath];
			NSParameterAssert(subpaths);
			[paths addObjectsFromArray:subpaths];
		}
	}
	return paths;
}

-(NSArray* )_productsAtPath:(NSString* )path error:(NSError** )error {
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString* filename = nil;
	NSMutableArray* products = [NSMutableArray array];
	while(filename = [enumerator nextObject]) {
		if([filename hasPrefix:@"."]) {
			continue;
		}
		NSString* filepath = [path stringByAppendingPathComponent:filename];
		if([filename hasSuffix:PGSchemaFileExtension]==NO) {
			continue;
		}
		BOOL isDirectory = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDirectory]==NO || isDirectory==YES) {
			continue;
		}
		if([[NSFileManager defaultManager] isReadableFileAtPath:filepath]==NO) {
			continue;
		}
		PGSchemaProduct* schemaproduct = [PGSchemaProduct schemaWithPath:filepath error:error];
		if(schemaproduct==nil) {
			return nil;
		}
		[products addObject:schemaproduct];
	}
	return products;
}

-(BOOL)_hasProductTableWithError:(NSError** )error {
	NSError* localError = nil;
	NSArray* bindings = [NSArray arrayWithObjects:[[self connection] database],PGSchemaName,PGSchemaTable,nil];
	PGResult* result = [[self connection] execute:[self _sqlfor:@"PGSchemaHasTable"] format:PGClientTupleFormatBinary values:bindings error:&localError];
	if(result==nil) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorDatabase description:[localError localizedDescription] path:nil];
		return NO;
	}
	if([result size]) {
		NSParameterAssert([result size]==1);
		return YES;
	}
	return NO;
}

-(BOOL)_hasProductInstalled:(PGSchemaProduct* )product error:(NSError** )error {
	// check for products table, return empty array if it doesn't yet exist
	NSError* localError = nil;
	NSArray* bindings = [NSArray arrayWithObjects:[[self connection] database],PGSchemaName,PGSchemaTable,nil];
	PGResult* result = [[self connection] execute:[self _sqlfor:@"PGSchemaHasTable"] format:PGClientTupleFormatBinary values:bindings error:&localError];
	if(result==nil) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorDatabase description:[localError localizedDescription] path:nil];
		return NO;
	}
	if([result size]) {
		NSParameterAssert([result size]==1);
		return YES;
	}
	return NO;
}

-(BOOL)_checkDependentProduct:(PGSchemaProduct* )product error:(NSError** )error {
	NSParameterAssert(product);
	// check to make sure product is in list of available products
	if([_products objectForKey:[product key]]==nil) {
		(*error) = [PGSchema errorWithCode:PGSchemaErrorDependency description:@"Schema product not found" path:nil];
		return NO;
	}
	// TODO
	return YES;
}


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
		case PGSchemaErrorSearchPath:
			reason = @"Invalid Search Path";
			break;			
		case PGSchemaErrorDependency:
			reason = @"Dependency Error";
			break;
		case PGSchemaErrorDatabase:
			reason = @"Database Error";
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

@end
