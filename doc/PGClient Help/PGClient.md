

# How to use PGClient

This framework is used to start, stop and restart a PostgresSQL server programatically, as a background process to the main executing process. The case for doing this is fairly limited, since you would ideally run your database server separately from any user-process. However, you may wish to have a feature-rich data storage engine in your application (you could also use CoreData or SQLite, of course). You should check out [[PGServer]] or [[PGFoundationServer]] example source code to see how you can use this framework in your own applications.

## An Introduction to compiling and using the framework

The `PGServerKit.framework` is compiled from the XCode project, to produce a framework. You should place this framework within your 'Frameworks' directory within your application bundle (a 'Copy Files' phase in your target). If you're creating a shell tool, it needs to reference the framework within a directory `../Frameworks` instead.

To access the server from your source code, create a controller class. If you're creating a Foundation command-line tool, here is how your `main()` method might look:

```objc
#import <Foundation/Foundation.h>
#import "PGFoundationServer.h"

int main (int argc, const char* argv[]) {
	int returnValue = 0;
	@autoreleasepool {
		controller = [[PGFoundationServer alloc] init];
		returnValue = [controller start];
	}
    return returnValue;
}
```

The `run` method for your controller should create a server object pointing to a particular data folder, and set the controller to be the PGServer delegate:

```objc
#import <PGServerKit/PGServerKit.h>

@implementation PGFoundationServer

-(void)run {
	PGServer* server = [PGServer serverWithDataPath:[self dataPath]];

	[self setServer:server];
	[[self server] setDelegate:self];
        ...
}

@end
```

This data path does not necessarily need to contain an existing set of data, since one of the tasks of PGServer is to initialize the data directory. Here's an example method which can return a data path
under the user's `~/Library/Application Support` folder:

```objc
@implementation PGFoundationServer

-(NSString* )dataPath {
	NSString* theIdent = @"PostgreSQL";
	NSArray* theAppFolder = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask, YES);
	NSParameterAssert([theAppFolder count]);
	return [[theAppFolder objectAtIndex:0] stringByAppendingPathComponent:theIdent];
}

@end
```

A run loop is required since PGServer currently uses timing mechanisms to check on the status of the server occasionally. For Cocoa applications, there is an implicit run loop. However, for Foundation (command line) applications you will need to create your own run loop. Here is the full `start` method:

```objc
@implementation PGFoundationServer

-(void)run {
	// create a server
	PGServer* server = [PGServer serverWithDataPath:[self dataPath]];
	// bind to server
	[self setServer:server];
	[[self server] setDelegate:self];
	
	// start the run loop
	double resolution = 300.0;
	BOOL isRunning;
	do {
		NSDate* theNextDate = [NSDate dateWithTimeIntervalSinceNow:resolution];
		isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:theNextDate];
	} while(isRunning==YES);
}

@end
```

Once a run loop is in place, it is possible to `start`, `stop`, `restart` and `reload` the server at will, but these must be called from external simuli. Here's a method which starts the server:

```objc
@implementation PGFoundationServer

-(void)start {
	PGServerState state = [[self server] state];
	if(state==PGServerStateUnknown) {
		[[self server] startWithNetworkBinding:[self hostname] port:[self port]];
	} else {
          // not sure we can start the server....
        }
}

@end
```

The methods `[PGServer start]`, `[PGServer stop]`, `[PGServer reload]` and `[PGServer restart]` simply send signals to the server and return a boolean success condition to indicate successful signalling.

To determine if a signalling operation was successful, check the `state` of the PGServer object as it changes. You can do this either by polling or by implementing the delegate method `pgserver:stateChange:`. Here's some example code which triggers signals based on the changing state of the PGServer object:

```objc
@implementation PGFoundationServer

-(void)pgserver:(PGServer* )server stateChange:(PGServerState)state {
	switch(state) {
		case PGServerStateAlreadyRunning:
		case PGServerStateRunning:
			printf("Server is ready to accept connections\n");
			printf("  PID = %d\n",[server pid]);
			printf("  Port = %lu\n",[server port]);
			printf("  Hostname = %s\n",[[server hostname] UTF8String]);
			printf("  Socket path = %s\n",[[server socketPath] UTF8String]);
			printf("  Uptime = %lf seconds\n",[server uptime]);
			break;
		case PGServerStateError:
			// error occured, so program should quit with -1 return value
			printf("Server error, quitting\n");
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
			break;
		case PGServerStateStopped:
			// quit the application
			printf("Server stopped, ending application\n");
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
			break;
	}
}

@end
```

You may want to display output from the server on the screen. In which case, you can pick up messages from the server by implementing the delegate method:

```objc
@implementation PGFoundationServer

-(void)pgserver:(PGServer* )server message:(NSString* )message {
  printf("%s\n",[message UTF8String]);
}

@end
```

In the following sections, we will go into further details on using the framework.

## PGServer Class

### Starting the server

There are four methods for starting the server:

```objc
@interface PGServer
-(BOOL)start;
-(BOOL)startWithPort:(NSUInteger)port;
-(BOOL)startWithPort:(NSUInteger)port socketPath:(NSString* )socketPath;
-(BOOL)startWithNetworkBinding:(NSString* )hostname port:(NSUInteger)port;
@end
```

The first of these methods will signal the server to start, allowing access to the database through local socket-based communication only (no access via the network). The second is similar, but uses a custom PostgreSQL port number for communication. The third method adds the ability to place the UNIX socket in a custom location. Finally, the fourth version binds the server to a network interface. You can bind to all network interfaces using "`*`" as the network binding parameter. To use the default PostgreSQL port use the global variable `PGServerDefaultPort` (the default port is usually 5432). Here are some examples:

```objc
  // start server with local communication only
  [server start];

  // start server and bind to all network interfaces with standard port
  [server startWithNetworkBinding:@"*" port:PGServerDefaultPort];
```

As well as setting the network binding as "`*`" (which binds the server to every network port) you can bind the server to particular ports on your computer by specifying the IP address of the port you wish to bind to. When calling `start`, the following things will occur:

  * The directory to hold the data is created, if not already existing
  * The data is initialised, if no data yet exists
  * Otherwise, it is determined if the server is already running
  * The properties for the server (hostname, port, socket directory, uptime, etc) are set

The server object will eventually settle to either `PGServerStateRunning` or `PGServerStateAlreadyRunning` in the background. If there is an error starting up the server, the state will change to `PGServerStateError`.


### Stopping, reloading and restarting

You can use the following methods to perform other server operations:

```
@interface PGServer

-(BOOL)stop;
-(BOOL)restart;
-(BOOL)reload;

@end
```

Again, these generally return directly with a success condition, but the state of the server will change in the background to reflect progress of completion. The `reload` method will simply ask the server to reload the configuration files, whereas `restart` will stop and then start the server. You will want to use the former method to pick up certain configuration file changes.

### Server state

When you send a `start`, `stop`, `reload` or `restart` message to the server object, the state of the server will change to reflect progress in carrying out the operation.

The state of the server can be determined using the `state` method, which return an enumeration of type `PGServerState`. An english-language version of the state can be determined using the `stateAsString` class method. Some values of PGServerState are:

 * `PGServerStateUnknown` - State of the server is unknown, but treat this as meaning 'stopped'
 * `PGServerStateInitializing` - Server is being initialized for the first time (data directory is being populated) during startup
 * `PGServerStateAlreadyRunning` - Attempt made to start server, but already running.
 * `PGServerStateRunning` - Server has been started up and is now ready to accept connections
 * `PGServerStateError` - Server was being started up, but an error occured. Treat as meaning 'stopped'.
 * `PGServerStateStopped` - Server has been stopped

There are various other states that occur, but they are only transient. Once the server has reached state `PGServerStateRunning` or `PGServerStateAlreadyRunning`  the `pid`, `hostname`, `port`, `socketPath`, `dataPath` and `uptime` properties will be set.

### Returning information about the server

The following properties provide information on the server:

```
@interface PGServer

@property (readonly) NSString* version;  // server version
@property (readonly) PGServerState state;  // server state
@property (readonly) NSString* dataPath;  // location of data
@property (readonly) NSString* socketPath;  // location of communication socket
@property (readonly) NSString* hostname;  // bound network address
@property (readonly) NSUInteger port;  // server port
@property (readonly) int pid;  // process identifier
@property (readonly) NSTimeInterval uptime;  // uptime for the server in seconds

// return english-language version of the server state
+(NSString* )stateAsString:(PGServerState)theState;

@end
```

### Implementing a delegate

Your delegate should implement optional methods in the `<PGServerDelegate>` protocol:

```objc
@protocol PGServerDelegate <NSObject>

@optional
-(void)pgserver:(PGServer* )sender stateChange:(PGServerState)state;
-(void)pgserver:(PGServer* )sender message:(NSString* )message;

@end
```

The first method is called by the server whenever the server state changes. The second method is called when the server emits a message. Here is an example of implementing these methods:

```objc
@implementation PGFoundationServer

-(void)pgserver:(PGServer* )server message:(NSString* )message {
	printf("%s\n",[message UTF8String]);
}

-(void)pgserver:(PGServer* )sender stateChange:(PGServerState)state {
	printf("Server state change: %s\n",[[PGServer stateAsString:state] UTF8String]);
}

@end
```

## Configuration, Access Control  and Encryption

### The PGServerConfiguration class

The server configuration file is kept in the data folder in a file named `postgres.conf`, and can be edited directly or manipulated through a `PGServerConfiguration` object. The following method is used to obtain the configuration:

```objc
@interface PGServer

-(PGServerPreferences* )configuration;

@end
```

The method will return `nil` if the configuration could not be loaded (for example, if the server has not yet been initialized). The configuration object has the following properties:

```objc
@interface PGServerConfiguration

@property (readonly) NSString* path;
@property (readonly) BOOL modified;
@property (readonly) NSArray* keys;
@property (readonly) NSArray* lines;

@end
```

The `path` property is the path to the configuration file. The `modified` is set to `YES` when a modification of the properties has occured. The `keys` property is an array of `NSString` objects for the modifiable configuration parameters, and `lines` is an array of `PGServerConfigurationLine` objects (you wouldn't normally need to use this).

The parameters are described here: "http://www.postgresql.org/docs/9.1/static/runtime-config.html".  Each parameter consists of a key, value, suffix, comment and flag to indicate if the parameter is enforced. If any parameter isn't being enforced, the server will use default values. In addition, the `listen_addresses` and `port` parameters are never enforced, since these are passed using the `start` method.

To get parameter properties, use the following methods:

```objc
@interface PGServerConfiguration

-(NSObject* )objectForKey:(NSString* )key;
-(NSString* )suffixForKey:(NSString* )key;
-(BOOL)enabledForKey:(NSString* )key;
-(NSString* )commentForKey:(NSString* )key;

@end
```

Returned objects are generally of class `NSString` or `NSNumber` (where the `NSNumber` is either a `BOOL`, `NSInteger` or `double` variant). The "suffix" is returned for NSInteger type parameters when specifying time or memory units, for example 'kB', 'MB', 'ms' or 'sec'.

To set parameter values, use the following methods:

```
@interface PGServerConfiguration

-(BOOL)setObject:(NSObject* )value forKey:(NSString* )key error:(NSError** )error;
-(BOOL)setEnabled:(BOOL)enabled forKey:(NSString* )key;
-(BOOL)setSuffix:(NSObject* )value forKey:(NSString* )key error:(NSError** )error;

@end
```

These methods will return NO if there was an issue setting the parameter. There are also some helper functions:

```
@interface PGServerConfiguration

-(BOOL)setString:(NSString* )value forKey:(NSString* )key error:(NSError** )error;
-(BOOL)setInteger:(NSInteger)value forKey:(NSString* )key error:(NSError** )error;
-(BOOL)setDouble:(double)value forKey:(NSString* )key error:(NSError** )error;
-(BOOL)setBool:(BOOL)value forKey:(NSString* )key error:(NSError** )error;

@end
```

As well as returning NO, an error object is returned in when there is a parameter mis-match. For example:

```objc
  PGServerConfiguration* config = [server configuration];
  NSError* error = nil;
  if([config setDouble:0.5 forKey:@"max_connections" error:&error]==NO) {
    NSLog(@"Error: %@",error);
  }
```

You can use two methods to write the configuration file, or revert it to the same as the configuration file on disk:

```objc
@interface PGServerConfiguration

-(BOOL)load;
-(BOOL)save;

@end
```

These return YES on success, or NO on failure.

When parameters have been successfully set, the `modified` property of the `PGServerConfiguration` object will be set to `YES`. Here is some example code which sets server parameters and then writes the configuration back to disc, followed by a server reload:

```objc
  PGServerConfiguration* config = [server configuration];
  NSError* error = nil;
  [config setInteger:20 forKey:@"max_connections" error:&error];
  [config setBool:YES forKey:@"ssl" error:&error];
  [config setInteger:128 suffix:@"kB" forKey:@"shared_buffers" error:&error];
  if(error) {
    // revert configuration
    NSLog(@"Error: %@",error);
    [config load];
  } else if([config modified]) {
    // save to disk, and signal server to reload
    [config save];
    [server reload];
  }
```

See the sample code in `PGServer` for further examples of modifying the configuration file.

### The PGServerHostAccess class

By default, the server is available to all locally running processes and/or all remote clients, depending on whether the hostname is set. In addition, any local user is 'trusted' without requiring password. Access control will need to be implemented to ensure that access to the server instance is secured. The PGServerHostAccess class can be used to change who has access to the server, locally and remotely,
through a series of rules, which are processed in sequential order.

The host access control file is kept in the data folder in a file named `pg_hba.conf`, and can be edited directly or manipulated through a `PGServerHostAccess` object. The following method is used to obtain it:

```objc
@interface PGServer

-(PGServerHostAccess* )hostAccess;

@end
```

The method will return `nil` if the host access information could not be loaded (for example, if the server has not yet been initialized). The object has the following properties and methods for loading and saving the host access file:

```objc
@interface PGServerHostAccess

@property (readonly) NSString* path;
@property (readonly) BOOL modified;

-(BOOL)load;
-(BOOL)save;

@end
```

The `load` and `save` methods return `NO` if the operation fails. The contents of this file are described here: http://www.postgresql.org/docs/9.1/static/auth-pg-hba-conf.html

To iterate through the rules, to remove a rule or move it to another position, use the following methods:

```objc
@interface PGServerHostAccess

@property (readonly) NSUInteger count;

-(PGServerHostAccessRule* )ruleAtIndex:(NSUInteger)i;
-(PGServerHostAccessRule* )removeRuleAtIndex:(NSUInteger)i;
-(void)insertRule:(PGServerHostAccessRule* )rule atIndex:((NSUInteger)i;

@end
```

For example, to print out the rules in the file use the following code:

```objc
  PGServer* server = ...;
  PGPGServerHostAccess* hostAccess = [server hostAccess];
  for(NSUInteger i = 0; i < [hostAccess count]; i++) {
    printf(@"%s",[[hostAccess ruleAtIndex:i] UTF8String]);
  }
```

The `PGServerHostAccessRule` class has the following methods:

```objc
@interface PGServerHostAccessRule

@property PGServerHostAccessType type;
@property NSString* addressMask;
@property PGServerHostAccessMethod method;

-(NSArray* )options;
-(NSString* )valueForOption:(NSString* )option;
-(void)setValue:(NSString* )value forOption:(NSString* )option;

@end
```

TBD

### Encrypted data transfer

TBD

## Performing backups

TBD

## Examples

There are two examples of embedding a server, which are part of the XCode project. The first is the [[PGServer]] which demonstrates all the features of embedding a server in a Cocoa application, and includes demonstrations of all the features of PGServerKit. The second is [[PGFoundationServer]] which is a much simpler command-line example.

## Limitations

There are some limitations and future enhancements. Let me know what's important to you and I will take a look.

 * Shared memory issues? Are there any, especially as max_connections becomes configurable
 * Split backups into smaller pieces (1GB files)
 * Clustering and master/slave configurations

