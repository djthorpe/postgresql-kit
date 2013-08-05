
#import "PGApplication.h"
#import "PGClientView.h"

@implementation PGClientView

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGClientView" bundle:nil];
    if (self) {
        // Custom initialization
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)viewDidLoad {
    [super viewDidLoad];
	[_statusLabel setText:@"Disconnected"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doConnect:(id)sender {
	PGApplication* app = (PGApplication* )[[UIApplication sharedApplication] delegate];
	NSParameterAssert(app);
	BOOL success = [app connect];
	if(success) {
		[_statusLabel setText:@"Connected"];
	} else {
		[_statusLabel setText:@"Disconnected"];
	}
}

@end
