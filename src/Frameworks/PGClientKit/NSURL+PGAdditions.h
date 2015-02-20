
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

@interface NSURL (PGAdditions)

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on the
 *  default local socket.
 *
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithLocalDatabase:(NSString* )database username:(NSString* )username params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  local socket, and use a particular port.
 *
 *  @param path     path for the local socket file (not the socket file itself), or nil.
 *  @param port     port for the socket file, or 0 for default port number.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithSocketPath:(NSString* )path port:(NSUInteger)port database:(NSString* )database username:(NSString* )username params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on the default port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithHost:(NSString* )host ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on a non-standard port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param port     The port number to connect to. Uses the default port if this is 0
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
+(id)URLWithHost:(NSString* )host port:(NSUInteger)port ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate a URL from a dictionary of postgresql
 *  parameters. The parameters that can be provided are described in the
 *  postgresql manual, but the following are used: user, host, hostaddr, dbname
 *  sslmode, port, password. Any remaining parameters (for example,
 *  connect_timeout, application_name, client_encoding) are provided as a query
 *  for the URL. On invalid parameters, nil is returned.
 *
 *  @param params The dictionary of parameters
 *
 *  @return An NSURL object
 */
+(id)URLWithPostgresqlParams:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  local socket, and use a particular port.
 *
 *  @param path     path for the local socket file (not the socket file itself), or nil.
 *  @param port     port for the socket file, or 0 for default port number.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithSocketPath:(NSString* )path port:(NSUInteger)port database:(NSString* )database username:(NSString* )username params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on the
 *  default local socket.
 *
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithLocalDatabase:(NSString* )database username:(NSString* )username params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on the default port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithHost:(NSString* )host ssl:(BOOL)ssl username:(NSString* )username database:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate PostgreSQL connection URL's. The URL
 *  which is generated will allow connection to a PostgeSQL instance on a
 *  remote host on a non-standard port, addressed by name, IP4 or IP6 address.
 *
 *  @param host     Hostname, IP4 or IP6 address. If nil, localhost is assumed.
 *  @param port     The port number to connect to. Uses the default port if this is 0
 *  @param ssl      If YES, SSL communication will be required, or else it is preferred.
 *  @param database Name of the database to connect to, or nil
 *  @param username Username to authenticate against. When nil, does not pass username
 *  @param params   Additional parameters for the connection
 *
 *  @return An NSURL object
 */
-(id)initWithHost:(NSString* )host port:(NSUInteger)port ssl:(BOOL)ssl username:(NSString* )username  database:(NSString* )database params:(NSDictionary* )params;

/**
 *  NSURL helper function to generate a URL from a dictionary of postgresql
 *  parameters. The parameters that can be provided are described in the
 *  postgresql manual, but the following are used: user, host, hostaddr, dbname
 *  sslmode, port, password. Any remaining parameters (for example,
 *  connect_timeout, application_name, client_encoding) are provided as a query
 *  for the URL. On invalid parameters, nil is returned.
 *
 *  @param params The dictionary of parameters
 *
 *  @return An NSURL object
 */
-(id)initWithPostgresqlParams:(NSDictionary* )params;

/**
 *  Returns a dictionary of parameters from the NSURL object
 *
 *  @return An immutable dictionary of parameters, as described in the 
 *    postgresql manual. On invalid URL, nil is returned.
 */
-(NSDictionary* )postgresqlParameters;

/**
 *  NSURL helper to determine if the URL is a valid socket-path URL
 *
 *  @return YES if the URL is a valid socket-path URL.
 */
-(BOOL)isSocketPathURL;

/**
 *  NSURL helper to determine if the URL is a valid remote host URL
 *
 *  @return YES if the URL is a valid remote host URL.
 */
-(BOOL)isRemoteHostURL;

@end
