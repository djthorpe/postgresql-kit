
#import <Foundation/Foundation.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface Application : NSObject {
	FLXPostgresConnection* connection;
}

//

@property (retain) FLXPostgresConnection* connection;

//

-(id)initWithURL:(NSURL* )theURL;
-(void)doWork;

@end
