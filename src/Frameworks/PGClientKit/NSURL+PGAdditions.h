
#import <Foundation/Foundation.h>

@interface NSURL (PGAdditions)

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on the
 *  default local socket.
 *
 *  @param database Name of the database to connect to, or nil
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithLocalDatabase:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on the default port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param database Name of the database to connect to, or nil
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithHost:(NSString* )host database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on a non-standard port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param port     The port number to connect to. Uses the default port if this is 0
 *  @param database Name of the database to connect to, or nil
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithHost:(NSString* )host port:(NSUInteger)port database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on the
 *  default local socket.
 *
 *  @param database Name of the database to connect to, or nil
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithLocalDatabase:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on the default port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param database Name of the database to connect to, or nil
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithHost:(NSString* )host database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on a non-standard port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param port     The port number to connect to. Uses the default port if this is 0
 *  @param database Name of the database to connect to, or nil
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithHost:(NSString* )host port:(NSUInteger)port database:(NSString* )database ssl:(BOOL)ssl params:(NSDictionary* )params;

@end
