//
//  showpsViewController.m
//  showps
//
//  Created by yiyang yuan on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "showpsViewController.h"
#import "PSConnectionCommands.h"

@implementation showpsViewController

@synthesize bottomBarView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        connectionController = nil;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    connectionController = [[PSConnectionController alloc] initWithNibName:@"PSConnectionController" bundle:nil];
    [bottomBarView addSubview:connectionController.view];
//    CGRect frame = connectionController.view.bounds;
//    frame.origin.x = 200;
//    frame.origin.y = 11;
//    connectionController.view.frame = frame;
//    connectionController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
}

- (void)viewDidUnload
{
    [connectionController release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
