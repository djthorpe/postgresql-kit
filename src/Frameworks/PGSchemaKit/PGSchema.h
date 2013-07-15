
#import <Foundation/Foundation.h>

@interface PGSchema : NSObject {
	PGConnection* _connection;
	NSString* _name;
	NSMutableArray* _searchpath;
	NSArray* _schemas;
}

-(id)initWithConnection:(PGConnection* )connection name:(NSString* )name;

@end
