
#import <Foundation/Foundation.h>

@interface FLXPostgresConnection : NSObject {
  void* m_theConnection;
  NSString* m_theHost;
  int m_thePort;
  NSString* m_theUser;
  NSString* m_theDatabase;
  int m_theTimeout;
  FLXPostgresTypes* m_theTypes;
}

// properties
-(NSString* )host;
-(NSString* )user;
-(NSString* )database;
-(int)port;
-(int)timeout;

-(void)setHost:(NSString* )theHost;
-(void)setUser:(NSString* )theUser;
-(void)setDatabase:(NSString* )theDatabase;
-(void)setPort:(int)thePort;
-(void)setTimeout:(int)theTimeout;  

// connection methods
-(void)disconnect;
-(BOOL)connected;
-(void)connect;
-(void)connectWithPassword:(NSString* )thePassword;
-(void)reset;

// execution methods
-(NSString* )quote:(NSObject* )theObject;
-(FLXPostgresResult* )execute:(NSString* )theQuery;
-(FLXPostgresResult* )execute:(NSString* )theQuery values:(NSArray* )theValues types:(NSArray* )theTypes;

@end
