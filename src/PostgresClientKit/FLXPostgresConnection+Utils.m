
#import "PostgresClientKit.h"

@implementation FLXPostgresConnection (Utils)

-(NSArray* )databases {
	NSParameterAssert([self connected]);

	// read databases
	FLXPostgresResult* theResult = [self execute:@"SELECT datname FROM pg_database WHERE datistemplate=false"];
	NSParameterAssert(theResult);

	// enumerate databases
	NSMutableArray* theDatabases = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theDatabases addObject:[theRow objectAtIndex:0]];
	}
	
	// return databases
	return theDatabases;  
}

-(BOOL)createDatabase:(NSString* )theName {
	NSParameterAssert([self connected]);
	if([self execute:[NSString stringWithFormat:@"CREATE DATABASE %@",theName]]==nil) {
		return NO;
	}	
	return YES;
}

-(BOOL)databaseExistsWithName:(NSString* )theName {
	return [[self databases] containsObject:theName];
}

-(NSArray* )tables {
	return [self tablesForSchema:nil];
}

-(NSArray* )schemas {
	NSParameterAssert([self connected]);
	FLXPostgresResult* theResult = [self execute:@"SELECT DISTINCT schemaname FROM pg_tables ORDER BY schemaname"];
	NSParameterAssert(theResult);	
	// enumerate schemas
	NSMutableArray* theSchemas = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theSchemas addObject:[theRow objectAtIndex:0]];
	}
	// return schemas
	return theSchemas;      
}

-(NSArray* )tablesForSchema:(NSString* )theName {
	NSParameterAssert([self connected]);
	NSString* theQuery = nil;
	if(theName==nil) {
		theQuery = @"SELECT tablename FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') ORDER BY tablename";		
	} else {
		theQuery = [NSString stringWithFormat:@"SELECT tablename FROM pg_tables WHERE schemaname=%@",[self quote:theName]];
	}
	FLXPostgresResult* theResult = [self execute:theQuery];
	NSParameterAssert(theResult);	
	// enumerate tables
	NSMutableArray* theTables = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theTables addObject:[theRow objectAtIndex:0]];
	}
	// return tables
	return theTables;      
}

-(NSArray* )tablesForSchemas:(NSArray* )theNames {
	NSParameterAssert([self connected]);
	NSParameterAssert(theNames);
	if([theNames count]==0) {
		return [self tablesForSchema:nil];
	}
	FLXPostgresResult* theResult = [self execute:[NSString stringWithFormat:@"SELECT tablename FROM pg_tables WHERE schemaname IN (%@) ORDER BY tablename",[self quoteArray:theNames]]];
	NSParameterAssert(theResult);	
	// enumerate tables
	NSMutableArray* theTables = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count] >= 1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theTables addObject:[theRow objectAtIndex:0]];
	}
	// return tables
	return theTables;      
}

-(BOOL)tableExistsWithName:(NSString* )theTable inSchema:(NSString* )theSchema {
	return [[self tablesForSchema:theSchema] containsObject:theTable];
}
							
-(NSString* )quoteArray:(NSArray* )theArray {
	NSParameterAssert(theArray && [theArray count]);
	// returns a comma-separated string of quoted objects
	NSMutableArray* theQuotedObjects = [NSMutableArray arrayWithCapacity:[theArray count]];
	for(NSObject* theObject in theArray) {
		[theQuotedObjects addObject:[self quote:theObject]];
	}
	return [theQuotedObjects componentsJoinedByString:@","];
}


@end
