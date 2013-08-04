
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
	[_clientVersionLabel setText:@"CLIENT VERSION"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
