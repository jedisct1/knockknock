//
//  AppDelegate.h
//  KnockKnock
//
//  Created by Frank Denis on 5/20/12.
//  Copyright (c) 2012 Frank Denis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSStreamDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
