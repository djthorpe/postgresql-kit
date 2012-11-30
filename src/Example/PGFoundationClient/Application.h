
#import <Foundation/Foundation.h>
#import <PGClientKit/PGClientKit.h>

@interface Application : NSObject <PGConnectionDelegate>

@property int signal;
@property PGConnection* db;

-(int)run;

@end
