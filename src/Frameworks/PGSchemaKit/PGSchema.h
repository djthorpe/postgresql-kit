
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject {
	PGConnection* _connection;
	NSString* _name;
	NSBundle* _bundle;
	NSMutableArray* _searchpath;
	NSMutableDictionary* _products;
}

// constructor
-(id)initWithConnection:(PGConnection* )connection name:(NSString* )name;

// properties
@property (readonly) NSArray* products;
@property (readonly) PGConnection* connection;

// methods
+(NSArray* )defaultSearchPath;
-(BOOL)addSearchPath:(NSString* )path error:(NSError** )error;
-(BOOL)addSearchPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;
-(BOOL)create:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
-(BOOL)drop:(PGSchemaProduct* )product dryrun:(BOOL)isDryrun error:(NSError** )error;
@end
