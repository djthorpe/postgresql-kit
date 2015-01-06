
#import <Foundation/Foundation.h>

@interface Terminal : NSObject

// properties
@property NSString* prompt;

// methods
-(NSString* )readline;
-(void)addHistory:(NSString* )line;
-(void)printf:(NSString* )format,...;

@end
