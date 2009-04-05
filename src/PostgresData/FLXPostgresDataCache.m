
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

static FLXPostgresDataCache* FLXSharedCache = nil;

void dynamicPropertySetter(id self, SEL _cmd, id object) {
	NSLog(@"dynamic set %@ %@ => %@",self,NSStringFromSelector(_cmd),object);
}

void dynamicPropertyGetter(id self, SEL _cmd) {
	NSLog(@"dynamic get %@ %@",self,NSStringFromSelector(_cmd));	
}

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

+(NSString* )_camelCaseForIdentifier:(NSString* )theName {
	NSParameterAssert(theName && [theName length] > 0);
	if([theName length]==1) {
		return [theName uppercaseString];
	}
	NSString* firstChar = [[theName substringToIndex:1] uppercaseString];
	NSString* restOfChars = [theName substringFromIndex:1];
	return [NSString stringWithFormat:@"%@%@",firstChar,restOfChars];
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
	} @catch(NSException* theException) {
		[self _delegateException:theException];
		return nil;
	}	
	return theKey;	
}


////////////////////////////////////////////////////////////////////////////////
// register setter and getter properties for a class

-(void)_registerPropertyImplementationForContext:(FLXPostgresDataObjectContext* )theContext {
	NSParameterAssert(theContext);
	Class theClass = NSClassFromString([theContext className]);
	NSParameterAssert(theClass);
	// get properties from the object, determine if there are implementations
	// for these properties - if not, then they are dynamic and we need to put
	// our own versions in place, I think!
	unsigned int numProperties;	
	objc_property_t* properties = class_copyPropertyList(theClass,&numProperties);
	for(unsigned int i = 0; i < numProperties; i++) {
		const char* propertyName = property_getName(properties[i]);
		const char* propertyAttributes = property_getAttributes(properties[i]);
		// continue if property is not the same as a column name
		if([[theContext tableColumns] containsObject:[NSString stringWithUTF8String:propertyName]]==NO) continue;
		// determine setter & getter
		SEL theSetter;
		if(strlen(propertyName)==1) {
			theSetter = NSSelectorFromString([NSString stringWithFormat:@"set%c:",toupper(propertyName[0])]);
		} else {
			theSetter = NSSelectorFromString([NSString stringWithFormat:@"set%c%s:",toupper(propertyName[0]),propertyName+1]);
		}			
		SEL theGetter = NSSelectorFromString([NSString stringWithFormat:@"%s",propertyName]);	
		IMP setterImplementation = (IMP)dynamicPropertySetter;
		IMP getterImplementation = (IMP)dynamicPropertyGetter;

		NSLog(@"property %s setter = %@, getter = %@, attributes = %s",propertyName,NSStringFromSelector(theSetter),NSStringFromSelector(theGetter),propertyAttributes);
		
		// add these methods to the class
		if(class_addMethod(theClass,theSetter,setterImplementation,"v@:@")==NO) {
			NSLog(@"Unable to add setter method '%@' for class %@",NSStringFromSelector(theSetter),[theContext className]);
		}
		if(class_addMethod(theClass,theGetter,getterImplementation,"v@:")==NO) {
			NSLog(@"Unable to add getter method '%@' for class %@",NSStringFromSelector(theGetter),[theContext className]);
		}			
	}
    free(properties);	
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
	NSString* thePrimaryKey = [theClass primaryKey] ? [theClass primaryKey] : [self _primaryKeyForTableName:theTableName];
	if(thePrimaryKey==nil) {
		return nil;
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
	// register the properties
	[self _registerPropertyImplementationForContext:theContext];
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
		NSObject* thePrimaryValue = [[self connection] insertRowForTable:[theContext tableName] values:columnValues columns:columnNames primaryKey:[theContext primaryKey] inSchema:[theContext schema]];
		NSParameterAssert(thePrimaryValue);
		// set the primary value
		[theObject setValue:thePrimaryValue forKey:[theContext primaryKey]];
	} else {
		[[self connection] updateRowForTable:[theContext tableName] values:columnValues columns:columnNames primaryKey:[theContext primaryKey] primaryValue:[theObject primaryValue] inSchema:[theContext schema]];
	}
	// commit modified information
	[theObject commit];
	// return success
	return YES;
}

-(BOOL)saveObject:(FLXPostgresDataObject* )theObject {
	return [self saveObject:theObject full:NO];
}

@end
