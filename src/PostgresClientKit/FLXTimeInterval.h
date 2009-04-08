
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

+(FLXTimeInterval* )intervalWithSeconds:(NSNumber* )theSeconds days:(NSNumber* )days months:(NSNumber* )months;

@end
