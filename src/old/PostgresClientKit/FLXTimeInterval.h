
#import <Foundation/Foundation.h>

// encapsulates a NSTimeInterval value (a double float) and the day and month intervals

@interface FLXTimeInterval : NSObject {
	NSTimeInterval seconds;
	NSInteger days;
	NSInteger months;	
}

@property (assign) NSTimeInterval seconds;
@property (assign) NSInteger days;
@property (assign) NSInteger months;

+(FLXTimeInterval* )interval;
+(FLXTimeInterval* )intervalWithSeconds:(NSTimeInterval)theSeconds days:(NSInteger)days months:(NSInteger)months;

@end
