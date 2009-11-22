
#import <Foundation/Foundation.h>

@interface FLXPostgresTypes : NSObject {
	FLXPostgresConnection* m_theConnection;
}

@property (readonly,retain) FLXPostgresConnection* connection;

@end
