
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject {
	PGConnection* _connection;
	NSString* _name;
	NSMutableArray* _searchpath;
	NSArray* _schemas;
}

// constructor
-(id)initWithConnection:(PGConnection* )connection name:(NSString* )name;

// properties
@property (readonly) NSArray* schemas;

// methods
-(BOOL)addSchemaPath:(NSString* )schemaPath error:(NSError** )error;

@end
