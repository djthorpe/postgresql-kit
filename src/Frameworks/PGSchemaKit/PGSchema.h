
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject {
	PGConnection* _connection;
	NSString* _name;
	NSMutableArray* _searchpath;
	NSMutableDictionary* _products;
}

// constructor
-(id)initWithConnection:(PGConnection* )connection name:(NSString* )name;

// properties
@property (readonly) NSArray* products;

// methods
+(NSArray* )defaultSearchPath;
-(BOOL)addSearchPath:(NSString* )path error:(NSError** )error;
-(BOOL)addSearchPath:(NSString* )path recursive:(BOOL)isRecursive error:(NSError** )error;

@end
