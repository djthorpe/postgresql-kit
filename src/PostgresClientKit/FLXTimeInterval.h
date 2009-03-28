
#import <Foundation/Foundation.h>

// encapsulates a NSTimeInterval value (a double float) and the day and month intervals

@interface FLXTimeInterval : NSObject {
	NSTimeInterval interval;
	NSInteger days;
	NSInteger months;	
}

@property (assign) NSTimeInterval interval;
@property (assign) NSInteger days;
@property (assign) NSInteger months;

+(FLXTimeInterval* )intervalWithSeconds:(NSNumber* )theSeconds days:(NSNumber* )days months:(NSNumber* )months;

@end
