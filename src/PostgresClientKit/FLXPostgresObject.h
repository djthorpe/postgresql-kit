
#import <Foundation/Foundation.h>

@interface FLXPostgresObject : NSObject {

}

+(FLXPostgresObject* )newFileDescriptorForConnection:(FLXPostgresConnection* )theConnection;
+(FLXPostgresObject* )openFileDescriptor:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection;
+(BOOL)deleteFileDescriptor:(NSUInteger)fd forConnection:(FLXPostgresConnection* )theConnection;

-(void)writeData:(NSData* )theData;
-(NSData* )readDataOfLength:(NSUInteger)length;
-(NSData* )readDataToEndOfFile;
-(NSUInteger)offsetInFile;
-(NSUInteger)seekToEndOfFile;
-(void)seekToFileOffset:(NSUInteger)offset;
-(NSUInteger)fileDescriptor;
-(void)closeFile;

@end
