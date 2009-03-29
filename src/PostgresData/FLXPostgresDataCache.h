
#import <Foundation/Foundation.h>

@interface FLXPostgresDataCache : NSObject {
	id delegate;
	FLXPostgresConnection* connection;	
	NSMutableDictionary* context;
}

@property (assign) id delegate;
@property (retain) FLXPostgresConnection* connection;
@property (retain) NSMutableDictionary* context;

+(FLXPostgresDataCache* )sharedCache;

@end
