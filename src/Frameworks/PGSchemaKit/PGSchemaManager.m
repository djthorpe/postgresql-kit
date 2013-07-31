
#import "PGSchemaKit.h"
#import "PGSchemaKit+Private.h"

////////////////////////////////////////////////////////////////////////////////

NSString* PGSchemaErrorDomain = @"PGSchemaDomain";
NSString* PGSchemaFileExtension = @".schema.xml";
NSString* PGSchemaUserDefaultName = @"public";
NSString* PGSchemaSystemDefaultName = @"postgreskit";
NSString* PGSchemaTable = @"t_product";

////////////////////////////////////////////////////////////////////////////////

@implementation PGSchemaManager

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema {
	return [self initWithConnection:connection userSchema:usrschema systemSchema:nil];
}

-(id)initWithConnection:(PGConnection* )connection userSchema:(NSString* )usrschema systemSchema:(NSString* )sysschema {
	NSParameterAssert(connection);

	// default schema names
	if(usrschema==nil) {
		usrschema = PGSchemaUserDefaultName;
	}
	if(sysschema==nil) {
		sysschema = PGSchemaSystemDefaultName;
	}
	
	// initialize object
	self = [super init];
	if(self) {
		_connection = connection;
		_usrschema = [usrschema copy];
		_sysschema = [sysschema copy];
		_searchpath = [NSMutableArray array];
		_products = [NSMutableDictionary dictionary];
	}

	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize connection = _connection;
@synthesize systemSchema = _sysschema;
@synthesize userSchema = _usrschema;

@dynamic products;

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
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorSearchPath description:@"Invalid search path" path:path];
		return NO;
	}
	
	// add default search path
	if([_searchpath count]==0) {
		for(NSString* path in [PGSchemaManager defaultSearchPath]) {
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
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorDependency description:@"Schema product not found" path:nil];
		return NO;		
	}
	// check to make sure product is not already installed
	BOOL isInstalled = [self _hasProductInstalled:product error:error];
	if(*error) {
		return NO;
	}
	if(isInstalled) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorDependency description:@"Already installed" path:nil];
		return NO;		
	}
	NSArray* missing_products = [self _checkDependentProductsNV:[product productnv] error:error];
	if(missing_products==nil) {
		return NO;
	}
	if([missing_products count] > 0) {
		NSLog(@"Products to install: %@",missing_products);
		return NO;
	}

	// install product
	return [product createWithConnection:_connection dryrun:isDryrun error:error];
}

-(BOOL)drop:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSParameterAssert(product);
	return [product dropWithConnection:_connection dryrun:isDryrun error:error];
}

-(BOOL)update:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error {
	NSParameterAssert(product);
	return [product updateWithConnection:_connection dryrun:isDryrun error:error];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

+(NSString* )formatSQL:(NSString* )key attributes:(NSDictionary* )attr {
	NSParameterAssert(key);
	NSBundle* bundle = [NSBundle bundleForClass:self];
	NSString* format = NSLocalizedStringFromTableInBundle(key,@"PGSchemaKitSQL",bundle,@"");
	NSParameterAssert(format);
	
	// create a scanner object and use '$' as delimiter
	NSScanner* scanner = [NSScanner scannerWithString:format];
	NSCharacterSet* delimiter = [NSCharacterSet characterSetWithCharactersInString:@"$"];
	NSCharacterSet* alphanumeric = [NSCharacterSet characterSetWithCharactersInString:@"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
	NSMutableString* statement = [NSMutableString string];
	NSString* tmpstr = nil;
	NSInteger tmpint;
	while([scanner isAtEnd]==NO) {
		BOOL foundDelimiter = [scanner scanUpToCharactersFromSet:delimiter intoString:&tmpstr];
		[statement appendString:tmpstr];
		if(foundDelimiter==NO) {
			continue;
		}
		foundDelimiter = [scanner scanCharactersFromSet:delimiter intoString:&tmpstr];
		if(foundDelimiter==NO) {
			continue;
		}
		// scan in binding value $1, $2, etc
		if([scanner scanInteger:&tmpint]) {
			[statement appendFormat:@"%ld",tmpint];
			continue;
		}
		// scan in attribute name
		if([scanner scanCharactersFromSet:alphanumeric intoString:&tmpstr]) {
			NSString* value = [attr objectForKey:tmpstr];
			if(value==nil) {
				[statement appendFormat:@"$%@$",tmpstr];
			} else {
				[statement appendString:value];
			}
		} else {
			return nil;
		}
		// scan delimiter
		foundDelimiter = [scanner scanCharactersFromSet:delimiter intoString:&tmpstr];
		if(foundDelimiter==NO) {
			return nil;
		}
	}
	
	return statement;
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
	NSArray* bindings = [NSArray arrayWithObjects:[[self connection] database],[self systemSchema],PGSchemaTable,nil];
	PGResult* result = [[self connection] execute:[PGSchemaManager formatSQL:@"PGSchemaHasTable" attributes:nil] format:PGClientTupleFormatBinary values:bindings error:&localError];
	if(result==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorDatabase description:[localError localizedDescription] path:nil];
		return NO;
	}
	if([result size]) {
		NSParameterAssert([result size]==1);
		return YES;
	}
	return NO;
}

-(BOOL)_hasProductInstalled:(PGSchemaProduct* )product error:(NSError** )error {
	// TODO
	return NO;
}

-(NSArray* )_checkDependentProductsNV:(PGSchemaProductNV* )productnv error:(NSError** )error {
	NSParameterAssert(productnv);
	// check to make sure product is in list of available products
	if([_products objectForKey:[productnv key]]==nil) {
		(*error) = [PGSchemaManager errorWithCode:PGSchemaErrorDependency description:@"Missing schema product file" path:nil];
		return nil;
	}
	// has product been installed?
	
	// TODO
	return [NSArray array];
}

+(NSError* )errorWithCode:(PGSchemaErrorType)code description:(NSString* )description {
	return [self errorWithCode:code description:description path:nil];
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
		case PGSchemaErrorInternal:
			reason = @"Internal Error";
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
