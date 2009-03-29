
#import <Foundation/Foundation.h>

@interface FLXPostgresDataCache : NSObject {
	id delegate;
	FLXPostgresConnection* connection;	
	NSMutableDictionary* context;
	NSString* schema;
}

@property (assign) id delegate;
@property (retain) FLXPostgresConnection* connection;
@property (retain) NSMutableDictionary* context;
@property (retain) NSString* schema;

+(FLXPostgresDataCache* )sharedCache;

@end

@interface NSObject (FLXPostgresDataCacheDelegate)
-(void)dataCache:(FLXPostgresDataCache* )theCache error:(NSError* )theError;
@end
