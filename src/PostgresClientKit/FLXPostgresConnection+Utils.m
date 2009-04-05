
#import "PostgresClientKit.h"

@implementation FLXPostgresConnection (Utils)

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
	NSParameterAssert(theResult);
	NSParameterAssert([theResult affectedRows]==0 || [theResult affectedRows]==1);
	if([theResult affectedRows] == 0) return nil; // no primary key
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

////////////////////////////////////////////////////////////////////////////////

-(NSObject* )insertRowForTable:(NSString* )theTable values:(NSArray* )theValues columns:(NSArray* )theColumns primaryKey:(NSString* )thePrimaryKey inSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert([theValues count] > 0);
	NSParameterAssert([theColumns count] > 0);
	NSParameterAssert([theValues count]==[theColumns count]);
	NSParameterAssert(theTable);
	NSParameterAssert(theSchema);
	NSString* theColumnsQ = [theColumns componentsJoinedByString:@","];
	NSMutableString* theBindingsQ = [NSMutableString string];
	for(NSUInteger i = 0; i < [theColumns count]; i++) {
		[theBindingsQ appendFormat:(i ? @",$%u" : @"$%u"),(i+1)];
	}
	FLXPostgresResult* theResult = [self execute:[NSString stringWithFormat:@"INSERT INTO %@.%@ (%@) VALUES (%@) RETURNING %@",theSchema,theTable,theColumnsQ,theBindingsQ,thePrimaryKey] values:theValues];
	NSParameterAssert(theResult && [theResult affectedRows] == 1);
	NSArray* theRow = [theResult fetchRowAsArray];
	NSParameterAssert([theRow count]==1);
	NSParameterAssert([[theRow objectAtIndex:0] isKindOfClass:[NSObject class]]);
	return [theRow objectAtIndex:0];	
}

-(void)updateRowForTable:(NSString* )theTable values:(NSArray* )theValues columns:(NSArray* )theColumns primaryKey:(NSString* )thePrimaryKey primaryValue:(NSObject* )thePrimaryValue inSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert([theValues count] > 0);
	NSParameterAssert([theColumns count] > 0);
	NSParameterAssert([theValues count]==[theColumns count]);
	NSParameterAssert(thePrimaryKey);
	NSParameterAssert(thePrimaryValue && [thePrimaryValue isKindOfClass:[NSNull class]]==NO);
	NSParameterAssert(theTable);
	NSParameterAssert(theSchema);
	NSMutableString* theBindingsQ = [NSMutableString string];
	for(NSUInteger i = 0; i <= [theColumns count]; i++) {
		if(i==0) {
			// do nothing
		} else {
			[theBindingsQ appendFormat:@",%@=$%u",[theColumns objectAtIndex:(i-1)],(i+1)];
		}
	}
	[self execute:[NSString stringWithFormat:@"UPDATE %@.%@ SET %@ WHERE %@=$1",theSchema,theTable,theBindingsQ,thePrimaryKey] values:theValues];	
}

-(void)deleteRowForTable:(NSString* )theTable primaryKey:(NSString* )thePrimaryKey primaryValue:(NSObject* )thePrimaryValue inSchema:(NSString* )theSchema {
	NSParameterAssert([self connected]);
	NSParameterAssert(thePrimaryKey);
	NSParameterAssert(thePrimaryValue && [thePrimaryValue isKindOfClass:[NSNull class]]==NO);
	NSParameterAssert(theTable);
	NSParameterAssert(theSchema);
	[self execute:[NSString stringWithFormat:@"DELETE FROM %@.%@ WHERE %@=$1",theSchema,theTable,thePrimaryKey] value:thePrimaryValue];		
}
	
@end
