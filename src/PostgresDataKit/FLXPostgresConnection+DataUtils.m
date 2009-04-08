
#import "PostgresDataKit.h"
#import "PostgresDataKitPrivate.h"

@implementation FLXPostgresConnection (DataUtils)

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
