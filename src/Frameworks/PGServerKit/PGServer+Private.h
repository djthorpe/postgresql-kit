
@interface PGServer (Private)
+(NSString* )_bundlePath;
+(NSString* )_serverBinary;
+(NSString* )_initBinary;
+(NSString* )_libraryPath;
+(NSString* )_dumpBinary;
-(void)_delegateMessage:(NSString* )message;
-(void)_delegateMessageFromData:(NSData* )theData;
@end