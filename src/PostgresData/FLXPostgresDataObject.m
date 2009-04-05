
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

@implementation FLXPostgresDataObject

////////////////////////////////////////////////////////////////////////////////

@synthesize values;
@synthesize modifiedValues;
@synthesize context;
@synthesize modified;

////////////////////////////////////////////////////////////////////////////////

-(id)initWithContext:(FLXPostgresDataObjectContext* )theContext {
	NSParameterAssert(theContext);
	self = [super init];
	if (self != nil) {
		[self setValues:[[NSMutableDictionary alloc] init]];
		[self setModifiedValues:[[NSMutableDictionary alloc] init]];
		[self setContext:theContext];
		[self setModified:NO];
	}
	return self;
}

-(void)dealloc {
	[self setValues:nil];
	[self setModifiedValues:nil];
	[self setContext:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// methods which need to be overridden

+(NSString* )tableName {
	return nil;
}

+(NSArray* )tableColumns { // optional
	return nil;
}

+(NSString* )primaryKey { // optional
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// methods for key/value pairs

-(NSObject* )primaryValue {
	// always return primary value from existing set of values,
	// not from modified set of values
	return [[self values] objectForKey:[[self context] primaryKey]];
}

-(NSObject* )valueForKey:(NSString* )theKey {
	NSParameterAssert(theKey);
	NSObject* theValue = [[self modifiedValues] objectForKey:theKey];
	if(theValue==nil) {
		theValue = [[self values] objectForKey:theKey];
	}
	return theValue;
}

-(void)setValue:(NSObject* )theValue forKey:(NSString* )theKey {
	NSParameterAssert(theValue);
	NSParameterAssert(theKey);
	NSParameterAssert([[[self context] tableColumns] containsObject:theKey]);
	NSObject* existingValue = [self valueForKey:theKey];
	if([existingValue isEqual:theValue]==NO) {
		[[self modifiedValues] setObject:theValue forKey:theKey];		
		[self setModified:YES];
	}
}

-(NSArray* )modifiedTableColumns {
	return [[self modifiedValues] allKeys];
}

-(BOOL)isNewObject {
	// new object if primary value has not been set yet
	return ([self primaryValue]==nil) ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////
// commit & rollback

-(void)commit {
	for(NSString* theKey in [[self modifiedValues] allKeys]) {
		[[self values] setObject:[[self modifiedValues] objectForKey:theKey] forKey:theKey];
	}
	[[self modifiedValues] removeAllObjects];
	[self setModified:NO];	
}

-(void)rollback {
	[[self modifiedValues] removeAllObjects];
	[self setModified:NO];
}

////////////////////////////////////////////////////////////////////////////////
// resolve getting and setting of properties

+(BOOL)resolveInstanceMethod:(SEL)aSEL {
	NSLog(@"sel = %@",NSStringFromSelector(aSEL));
	FLXPostgresDataCache* theCache = [FLXPostgresDataCache sharedCache];
	if(theCache==nil) return [super resolveInstanceMethod:aSEL];
	FLXPostgresDataObjectContext* theContext = [theCache objectContextForClass:[self class]];
	if(theContext==nil) return [super resolveInstanceMethod:aSEL];
	IMP theMethod = [theContext implementationForSelector:aSEL];
	if(theMethod) {
		class_addMethod([self class],aSEL,theMethod,"v@:");
		return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}


////////////////////////////////////////////////////////////////////////////////
// debugging

-(NSString* )description {
	NSMutableArray* theValues = [NSMutableArray array];
	for(NSString* theKey in [[self context] tableColumns]) {
		if([theKey isEqual:[[self context] primaryKey]]) continue;
		[theValues addObject:[NSString stringWithFormat:@"%@=>%@",theKey,[self valueForKey:theKey]]];
	}
	return [NSString stringWithFormat:@"{ %@%@ => %@=>%@,%@ }",[[self context] className],[self modified] ? @"*" : @"",[[self context] primaryKey],[self primaryValue],[theValues componentsJoinedByString:@","]];
}


@end
