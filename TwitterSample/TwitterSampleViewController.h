//
//  TwitterSampleViewController.h
//  TwitterSample
//
//  Created by 玉山将志 on 2012/10/29.
//  Copyright (c) 2012年 玉山将志. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJson.h"
#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"


@interface TwitterSampleViewController : UIViewController
<
UIAlertViewDelegate
, NSURLConnectionDelegate
>
@property (retain, nonatomic) IBOutlet UIButton *signInOutBtn;

@end
