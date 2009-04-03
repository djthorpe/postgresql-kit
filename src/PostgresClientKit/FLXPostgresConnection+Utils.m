
#import "PostgresClientKit.h"

@implementation FLXPostgresConnection (Utils)

/*
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
*/
////////////////////////////////////////////////////////////////////////////////

-(NSArray* )databases {
	NSParameterAssert([self connected]);
	FLXPostgresResult* theResult = [self execute:@"SELECT DISTINCT catalog_name FROM information_schema.schemata"];
	NSParameterAssert(theResult && [theResult affectedRows]);	
	NSMutableArray* theDatabases = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count]==1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theDatabases addObject:[theRow objectAtIndex:0]];
	}
	return theDatabases;      	
}

-(NSArray* )schemas {
	NSParameterAssert([self connected]);
	NSString* theDatabaseQ = [self quote:[self database]];
	FLXPostgresResult* theResult = [self executeWithFormat:@"SELECT schema_name FROM information_schema.schemata WHERE catalog_name=%@",theDatabaseQ];
	NSParameterAssert(theResult && [theResult affectedRows]);	
	NSMutableArray* theSchemas = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count]==1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theSchemas addObject:[theRow objectAtIndex:0]];
	}
	return theSchemas;      
}

-(NSArray* )tablesInSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert(theSchema);
	NSString* theDatabaseQ = [self quote:[self database]];
	NSString* theSchemaQ = [self quote:theSchema];
	FLXPostgresResult* theResult = [self executeWithFormat:@"SELECT table_name FROM information_schema.tables WHERE table_catalog=%@ AND table_schema=%@ AND table_type='BASE TABLE'",theDatabaseQ,theSchemaQ];
	NSParameterAssert(theResult);
	NSMutableArray* theTables = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count]==1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theTables addObject:[theRow objectAtIndex:0]];
	}
	return theTables;      
}

-(NSString* )primaryKeyForTable:(NSString* )theTable inSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert(theTable);
	NSParameterAssert(theSchema);
	NSString* theDatabaseQ = [self quote:[self database]];
	NSString* theSchemaQ = [self quote:theSchema];
	NSString* theTableNameQ = [self quote:theTable];
	NSString* theJoin = @"information_schema.table_constraints T INNER JOIN information_schema.key_column_usage K ON T.constraint_name=K.constraint_name";
	NSString* theWhere = [NSString stringWithFormat:@"T.constraint_type='PRIMARY KEY' AND T.table_catalog=%@ AND T.table_schema=%@ AND T.table_name=%@",theDatabaseQ,theSchemaQ,theTableNameQ];
	FLXPostgresResult* theResult = [self executeWithFormat:@"SELECT K.column_name FROM %@ WHERE %@",theJoin,theWhere];
	NSParameterAssert(theResult && [theResult affectedRows] == 1);
	NSArray* theRow = [theResult fetchRowAsArray];
	NSParameterAssert([theRow count]==1);
	NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
	return [theRow objectAtIndex:0];
}

-(NSArray* )columnNamesForTable:(NSString* )theTable inSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert(theTable);
	NSParameterAssert(theSchema);
	NSString* theDatabaseQ = [self quote:[self database]];
	NSString* theSchemaQ = [self quote:theSchema];
	NSString* theTableNameQ = [self quote:theTable];
	FLXPostgresResult* theResult = [self executeWithFormat:@"SELECT column_name FROM information_schema.columns WHERE table_catalog=%@ AND table_schema=%@ AND table_name=%@",theDatabaseQ,theSchemaQ,theTableNameQ];
	NSParameterAssert(theResult && [theResult affectedRows]);
	NSMutableArray* theColumns = [NSMutableArray arrayWithCapacity:[theResult affectedRows]];
	NSArray* theRow = nil;
	while(theRow = [theResult fetchRowAsArray]) {
		NSParameterAssert([theRow count]==1);
		NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSString class]]);
		[theColumns addObject:[theRow objectAtIndex:0]];
	}
	return theColumns;
}

@end
