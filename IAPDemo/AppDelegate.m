//
//  AppDelegate.m
//  IAPDemo
//
//  Created by Charles.Yao on 2016/10/31.
//  Copyright © 2016年 com.pico. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor= [UIColor whiteColor];
    [self.window  makeKeyAndVisible];
    ViewController*rvc = [[ViewController alloc] init];
    self.window.rootViewController = rvc;

    
   /**启动IAP工具类*/
    [[IAPManager shared] startManager];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
     /**结束IAP工具类*/
    [[IAPManager shared] stopManager];
    
}

@end
