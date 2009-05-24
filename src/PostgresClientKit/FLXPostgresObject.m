
#import "PostgresClientKit.h"
#import "PostgresClientKitPrivate.h"

@implementation FLXPostgresObject

@synthesize connection;
@synthesize fileDescriptor;

NSString* FLXPostgresObjectErrorDomain = @"FLXPostgresObjectError";

////////////////////////////////////////////////////////////////////////////////

-(id)initWithConnection:(FLXPostgresConnection* )theConnection oid:(FLXPostgresOid)theOid {
	NSParameterAssert(theConnection);
	NSParameterAssert(theOid);
	self = [super init];
	if (self != nil) {
		connection = [theConnection retain];
		fileDescriptor = theOid;
	}
	return self;
}

-(void)dealloc {
	if([self fileDescriptor] && [[self connection] connected]) {
		[self closeFile];
	}
	[connection release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

+(FLXPostgresObject* )newObjectForConnection:(FLXPostgresConnection* )theConnection {
	// check connection
	NSParameterAssert(theConnection);
	if([theConnection connected]==NO) return nil;

	// create remote "LO"
	FLXPostgresOid theOid = lo_create([theConnection connection],0);
	if(theOid==0) return nil;
	
	// attach it to local object, return it
	return [[[FLXPostgresObject alloc] initWithConnection:theConnection oid:theOid] autorelease];
}

+(FLXPostgresObject* )openObjectForReading:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection {
	// check connection
	NSParameterAssert(theConnection);
	if([theConnection connected]==NO) return nil;

	// open remote "LO"
	FLXPostgresOid theOid = lo_open([theConnection connection],fd,INV_READ);
	if(theOid==0) return nil;

	// attach it to local object, return it
	return [[[FLXPostgresObject alloc] initWithConnection:theConnection oid:theOid] autorelease];
}

+(FLXPostgresObject* )openObjectForWriting:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection {
	// check connection
	NSParameterAssert(theConnection);
	if([theConnection connected]==NO) return nil;
	
	// open remote "LO"
	FLXPostgresOid theOid = lo_open([theConnection connection],fd,INV_READ | INV_WRITE);
	if(theOid==0) return nil;
	
	// attach it to local object, return it
	return [[[FLXPostgresObject alloc] initWithConnection:theConnection oid:theOid] autorelease];
}

+(BOOL)deleteObject:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection {
	// check connection
	NSParameterAssert(theConnection);
	if([theConnection connected]==NO) return NO;
	int isSuccess = lo_unlink([theConnection connection],fd);
	return (isSuccess==1) ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////

-(void)writeData:(NSData* )theData {
	if([[self connection] connected]==NO) {
		[FLXPostgresException raise:FLXPostgresObjectErrorDomain reason:@"Not connected"];
	}
	NSInteger bytesWritten = lo_write([[self connection] connection],[self fileDescriptor],[theData bytes],[theData length]);
	if(bytesWritten < 0) {
		[FLXPostgresException raise:FLXPostgresObjectErrorDomain reason:@"Error writing bytes to remote large object"];		
	}	
	NSParameterAssert(bytesWritten==[theData length]);
}

/*-(NSData* )readDataOfLength:(NSUInteger)length;
-(NSData* )readDataToEndOfFile;
-(NSUInteger)offsetInFile;
-(NSUInteger)seekToEndOfFile;
-(void)seekToFileOffset:(NSUInteger)offset;
-(void)closeFile;

*/

@end
