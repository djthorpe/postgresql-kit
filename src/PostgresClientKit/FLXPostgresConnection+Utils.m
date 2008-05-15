
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

-(NSArray* )tablesForSchema:(NSString* )theName {
	NSParameterAssert([self connected]);
	NSString* theQuery = [NSString stringWithFormat:@"SELECT tablename FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') %@",(theName ? [NSString stringWithFormat:@"AND schemaname=%@",[self quote:theName]] : @"")];
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

-(BOOL)tableExistsWithName:(NSString* )theTable inSchema:(NSString* )theSchema {
	return [[self tablesForSchema:theSchema] containsObject:theTable];
}

@end
