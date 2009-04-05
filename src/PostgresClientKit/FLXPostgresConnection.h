
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

// prepare / execute methods
-(FLXPostgresStatement* )prepare:(NSString* )theQuery;
-(FLXPostgresStatement* )prepareWithFormat:(NSString* )theQuery,...;
-(FLXPostgresResult* )execute:(NSString* )theQuery;
-(FLXPostgresResult* )executeWithFormat:(NSString* )theQuery,...;
-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement;
-(FLXPostgresResult* )execute:(NSString* )theQuery values:(NSArray* )theValues;
-(FLXPostgresResult* )execute:(NSString* )theQuery value:(NSObject* )theValue;
-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement values:(NSArray* )theValues;
-(FLXPostgresResult* )executePrepared:(FLXPostgresStatement* )theStatement value:(NSObject* )theValue;

// quote method
-(NSString* )quote:(NSObject* )theObject;

@end
