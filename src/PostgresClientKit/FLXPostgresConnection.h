
#import <Foundation/Foundation.h>

@interface FLXPostgresConnection : NSObject {
	void* m_theConnection;
	NSString* m_theHost;
	NSUInteger m_thePort;
	NSString* m_theUser;
	NSString* m_theDatabase;
	NSDictionary* m_theParameters;
	NSUInteger m_theTimeout;
	id delegate;
	FLXPostgresTypes* m_theTypes;
}

@property (assign) id delegate;
@property (assign) NSUInteger port;
@property (assign) NSUInteger timeout;
@property (retain) NSString* host;
@property (retain) NSString* user;
@property (retain) NSString* database;
@property (retain) NSDictionary* parameters;
@property (retain) FLXPostgresTypes* types;

// init with URL, use scheme pgsql only
// pgsql://<username>@<hostname>:<port>/<database>/
+(FLXPostgresConnection* )connectionWithURL:(NSURL* )theURL;

// return the 'scheme' used to construct a URL
+(NSString* )scheme;

// connection methods
-(void)connect;
-(void)connectWithPassword:(NSString* )thePassword;
-(void)disconnect;
-(BOOL)connected;
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

// delegate

@interface NSObject (FLXPostgresConnectionDelegate)
-(void)connection:(FLXPostgresConnection* )theConnection notice:(NSString* )theNotice;
-(void)connection:(FLXPostgresConnection* )theConnection willExecute:(NSObject* )theQuery values:(NSArray* )theValues;
@end
