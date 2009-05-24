
#import <Foundation/Foundation.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface Application : NSObject {
	FLXPostgresConnection* connection;
	NSMutableDictionary* stringCache;
}

//

@property (retain) FLXPostgresConnection* connection;
@property (retain) NSMutableDictionary* stringCache;

//

-(id)initWithURL:(NSURL* )theURL;
-(void)doWork;

@end
