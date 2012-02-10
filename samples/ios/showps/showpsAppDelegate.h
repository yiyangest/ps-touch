//
//  showpsAppDelegate.h
//  showps
//
//  Created by yiyang yuan on 2/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class showpsViewController;

@interface showpsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    showpsViewController * viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet showpsViewController * viewController;

@end
