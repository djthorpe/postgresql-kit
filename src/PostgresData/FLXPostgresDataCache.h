
#import <Foundation/Foundation.h>

@interface FLXPostgresDataCache : NSObject {
	id delegate;
	FLXPostgresConnection* connection;	
}

@property (assign) id delegate;
@property (retain) FLXPostgresConnection* connection;

+(FLXPostgresDataCache* )sharedCache;

@end
