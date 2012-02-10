//
//  showpsViewController.h
//  showps
//
//  Created by yiyang yuan on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSConnectionController.h"

@interface showpsViewController : UIViewController {
    PSConnectionController * connectionController;
}

@property (nonatomic, retain) IBOutlet UIView * bottomBarView;

@end
