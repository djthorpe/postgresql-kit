
#import <Foundation/Foundation.h>

@interface Terminal : NSObject

// properties
@property (retain) NSString* prompt;
@property (readonly) NSInteger columns;

// methods
-(NSString* )readline;
-(void)addHistory:(NSString* )line;
-(void)printf:(NSString* )format,...;

@end
