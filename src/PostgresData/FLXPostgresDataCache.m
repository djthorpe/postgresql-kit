
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

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
	NSArray* theColumns = nil;
	@try {
		theColumns = [[self connection] columnNamesForTable:theTableName inSchema:[self schema]];
		NSParameterAssert(theColumns);
	} @catch(NSException* theException) {
		[self _delegateException:theException];
		return nil;
	}	
	return theColumns;	
}

-(NSString* )_primaryKeyForTableName:(NSString* )theTableName {
	if([self connection]==nil) return nil;
	NSString* theKey = nil;
	@try {
		theKey = [[self connection] primaryKeyForTable:theTableName inSchema:[self schema]];
		NSParameterAssert(theKey);
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
	// TODO: check class is of right kind
//	if([theClass isKindOfClass:[FLXPostgresDataObject class]]==NO) {
//		return nil;
//	}
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
	[theContext setClassName:theClassString];
	[theContext setSchema:[self schema]];
	[theContext setClassName:theClassString];
	[theContext setTableName:theTableName];
	[theContext setPrimaryKey:thePrimaryKey];
	[theContext setTableColumns:theTableColumns];
	// place object in cache
	[[self context] setObject:theContext forKey:theClassString];
	// return the cbject
	return theContext;
}

////////////////////////////////////////////////////////////////////////////////
// create a new object

-(id)newObjectForClass:(Class)theClass {
	id theObject = [[theClass alloc] initWithContext:[self objectContextForClass:theClass]];
	if(theObject==nil || [theObject isKindOfClass:[FLXPostgresDataObject class]]==NO) {
		[theObject release];
		return nil;
	}

	// do stuff with object here
	
	return [theObject autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// commit changes to object - can throw an exception

-(BOOL)saveObject:(FLXPostgresDataObject* )theObject full:(BOOL)isFullCommit {
	NSParameterAssert(theObject);
	FLXPostgresDataObjectContext* theContext = [theObject context];
	NSParameterAssert(theContext);
	NSArray* columnNames = isFullCommit ? [theContext tableColumns] : [theObject modifiedTableColumns];
	NSParameterAssert(columnNames);
	if([columnNames count]==0) {
		// nothing to save!
		return YES;
	}
	// construct name, value arrays
	NSMutableArray* columnValues = [NSMutableArray arrayWithCapacity:[columnNames count]];
	for(NSString* theKey in columnNames) {
		NSObject* theValue = [theObject valueForKey:theKey];
		NSParameterAssert(theValue);
		[columnValues addObject:theValue];
	}
	// save object
	if([theObject isNewObject]) {
		[[self connection] insertRowForTable:[theContext tableName] values:columnValues columns:columnNames primaryKey:[theContext primaryKey] inSchema:[theContext schema]];
	} else {
		[[self connection] updateRowForTable:[theContext tableName] values:columnValues columns:columnNames primaryKey:[theContext primaryKey] primaryValue:[theObject primaryValue] inSchema:[theContext schema]];
	}
	// return success
	return YES;
}

-(BOOL)saveObject:(FLXPostgresDataObject* )theObject {
	return [self saveObject:theObject full:NO];
}

@end
