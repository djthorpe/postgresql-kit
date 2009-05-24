
#import <Foundation/Foundation.h>

@interface FLXPostgresObject : NSObject {
	FLXPostgresConnection* connection;
	NSUInteger fileDescriptor;
}

@property (retain,readonly) FLXPostgresConnection* connection;
@property (assign,readonly) NSUInteger fileDescriptor;

+(FLXPostgresObject* )newFileDescriptorForConnection:(FLXPostgresConnection* )theConnection;
+(FLXPostgresObject* )openFileDescriptor:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection;
+(BOOL)deleteFileDescriptor:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection;

-(void)writeData:(NSData* )theData;
-(NSData* )readDataOfLength:(NSUInteger)length;
-(NSData* )readDataToEndOfFile;
-(NSUInteger)offsetInFile;
-(NSUInteger)seekToEndOfFile;
-(void)seekToFileOffset:(NSUInteger)offset;
-(void)closeFile;

@end
