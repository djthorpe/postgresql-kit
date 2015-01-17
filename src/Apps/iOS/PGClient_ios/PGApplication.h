
#import <UIKit/UIKit.h>
#import <PGClientKit_ios/PGClientKit.h>

@interface PGApplication : UIResponder <UIApplicationDelegate> {
	PGConnection* _connection;
}

// properties
@property (strong, nonatomic) UIWindow* window;

// methods
-(BOOL)connect;

@end
