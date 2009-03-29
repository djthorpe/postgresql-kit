
#import "PostgresDataKit.h"

static FLXPostgresDataCache* FLXSharedCache = nil;

////////////////////////////////////////////////////////////////////////////////

@implementation FLXPostgresDataCache

@synthesize delegate;
@synthesize connection;
@synthesize context;
@synthesize schema;

////////////////////////////////////////////////////////////////////////////////
// singleton design pattern
// see http://www.cocoadev.com/index.pl?SingletonDesignPattern

+(FLXPostgresDataCache* )sharedCache {
	@synchronized(self) {
		if (FLXSharedCache == nil) {
			[[self alloc] init]; // assignment not done here
		}
	}
	return FLXSharedCache;
}

+(id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (FLXSharedCache == nil) {
			FLXSharedCache = [super allocWithZone:zone];
			return FLXSharedCache;  // assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
	return self;
}

-(id)retain {
	return self;
}

-(unsigned)retainCount {
	return UINT_MAX;  //denotes an object that cannot be released
}

-(void)release {
	// do nothing
}

-(id)autorelease {
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// constructor and destructor

-(id)init {
	self = [super init];
	if(self) {
		[self setContext:[[NSMutableDictionary alloc] init]];
		[self setSchema:@"public"];
	}
	return self;
}

-(void)dealloc {
	[self setDelegate:nil];
	[self setConnection:nil];
	[self setContext:nil];
	[self setSchema:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_delegateException:(NSException* )theException {
	// create an error
	NSError* theError = [NSError errorWithDomain:@"FLXPostgresDataCacheError" code:-1 userInfo:[NSDictionary dictionaryWithObject:[theException description] forKey:NSLocalizedDescriptionKey]];
	if([[self delegate] respondsToSelector:@selector(dataCache:error:)]) {
		[[self delegate] dataCache:self error:theError];
	} else {
		// re-throw the exception
		@throw theException;
	}
}

+(BOOL)_isValidIdentifier:(NSString* )theName {
	NSCharacterSet* illegalCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"] invertedSet];
	if([theName length]==0) return NO;
	NSRange theRange = [theName rangeOfCharacterFromSet:illegalCharacterSet];
	return (theRange.location==NSNotFound) ? YES : NO;
}

-(NSArray* )_columnsForTableName:(NSString* )theTableName {
	if([self connection]==nil) return nil;
	if([[self connection] connected]==NO) return nil;

	NSMutableArray* theColumns = nil;
	@try {
		NSString* theDatabaseQ = [[self connection] quote:[[self connection] database]];
		NSString* theSchemaQ = [[self connection] quote:[self schema]];
		NSString* theTableNameQ = [[self connection] quote:theTableName];
		FLXPostgresResult* theResult = [[self connection] executeWithFormat:@"SELECT column_name FROM information_schema.columns WHERE table_catalog=%@ AND table_schema=%@ AND table_name=%@",theDatabaseQ,theSchemaQ,theTableNameQ];
		if([theResult affectedRows]==0) return nil;
		theColumns = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
		NSArray* theRow = nil;
		while(theRow = [theResult fetchRowAsArray]) {
			NSParameterAssert([theRow count]==1);
			NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
			[theColumns addObject:[theRow objectAtIndex:0]];
		}
	} @catch(NSException* theException) {
		[self _delegateException:theException];
		return nil;
	}

	return theColumns;
}

-(NSString* )_primaryKeyForTableName:(NSString* )theTableName {
	if([self connection]==nil) return nil;
	if([[self connection] connected]==NO) return nil;
	if([self connection]==nil) return nil;
	if([[self connection] connected]==NO) return nil;	
	NSString* theKey = nil;
	@try {
		// SELECT 
		//   K.column_name 
		// FROM
		//   information_schema.table_constraints T INNER JOIN information_schema.key_column_usage K ON T.constraint_name = K.constraint_name
		// WHERE
		//   T.constaint_type='PRIMARY KEY' 
		//   AND T.table_catalog = XXX
		//   AND T.table_schema = YYY
		//   AND T.table_name = ZZZ
		NSString* theDatabaseQ = [[self connection] quote:[[self connection] database]];
		NSString* theSchemaQ = [[self connection] quote:[self schema]];
		NSString* theTableNameQ = [[self connection] quote:theTableName];
		NSString* theJoin = @"information_schema.table_constraints T INNER JOIN information_schema.key_column_usage K ON T.constraint_name=K.constraint_name";
		FLXPostgresResult* theResult = [[self connection] executeWithFormat:@"SELECT K.column_name FROM %@ WHERE T.constaint_type='PRIMARY KEY' AND T.table_catalog=%@ AND T.table_schema=%@ AND T.table_name=%@",theJoin,theDatabaseQ,theSchemaQ,theTableNameQ];
		if([theResult affectedRows] != 1) return nil;
		NSArray* theRow = [theResult fetchRowAsArray];
		NSParameterAssert([theRow count]==1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		theKey = [theRow objectAtIndex:0];
	} @catch(NSException* theException) {
		[self _delegateException:theException];
		return nil;
	}	
	return theKey;	
}

////////////////////////////////////////////////////////////////////////////////
// get object context for class

-(FLXPostgresDataObjectContext* )objectContextForClass:(Class)theClass {
	// turn class into a string
	NSString* theClassString = NSStringFromClass(theClass);
	if(theClassString==nil) {
		return nil;
	}
	// fetch context from cache
	FLXPostgresDataObjectContext* theContext = [[self context] objectForKey:theClassString];
	if(theContext) {
		return theContext;
	}
	// check class is of right kind
	if([theClass isKindOfClass:[FLXPostgresDataObject class]]==NO) {
		return nil;
	}
	// get table name
	NSString* theTableName = [theClass tableName];
	if([FLXPostgresDataCache _isValidIdentifier:theTableName]==NO) {
		return nil;
	}
	// get table columns
	NSArray* theTableColumns = [theClass tableColumns];
	if(theTableColumns==nil) {		
		theTableColumns = [self _columnsForTableName:theTableName];
	}
	if([theTableColumns count]==0) {
		return nil;
	}
	for(NSObject* theColumn in theTableColumns) {
		if([theColumn isKindOfClass:[NSString class]]==NO) {
			return nil;
		}
		if([FLXPostgresDataCache _isValidIdentifier:((NSString* )theColumn)]==NO) {
			return nil;
		}
	}
	// get primary key
	NSString* thePrimaryKey = [theClass primaryKey];
	if(thePrimaryKey==nil) {
		thePrimaryKey = [self _primaryKeyForTableName:theTableName];
	}
	if([FLXPostgresDataCache _isValidIdentifier:((NSString* )thePrimaryKey)]==NO) {
		return nil;
	}
	// create an object
	theContext = [[[FLXPostgresDataObjectContext alloc] init] autorelease];
	[theContext setTableName:theTableName];
	[theContext setPrimaryKey:thePrimaryKey];
	[theContext setTableColumns:theTableColumns];
	// place object in cache
	[[self context] setObject:theContext forKey:theClassString];
	// return the cbject
	return theContext;
}

@end
