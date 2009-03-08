
#import <Foundation/Foundation.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import <PostgresClientKit/PostgresClientKit.h>

@interface TestDelegate : NSObject {
	FLXPostgresConnection* m_theConnection;
	NSUInteger m_theTest;
	NSTimer* m_theTimer;
	BOOL m_isStopped;
}

-(BOOL)stopped;
-(BOOL)awakeThread;
-(void)stop;

@end
