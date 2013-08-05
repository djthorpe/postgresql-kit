
#import <UIKit/UIKit.h>

@interface PGClientView : UIViewController {
	__weak IBOutlet UILabel* _statusLabel;
}

-(IBAction)doConnect:(id)sender;

@end
