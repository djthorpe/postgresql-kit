
#import <PGServerKit/PGServerKit.h>

@protocol ControllerDelegate <NSObject>
-(PGServerPreferences* )configuration;
-(void)restartServer;
-(void)reloadServer;
@end
