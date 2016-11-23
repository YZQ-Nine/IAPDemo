//
//  NSDate+category.m
//  IAPDemo
//
//  Created by Charles.Yao on 2016/10/31.
//  Copyright © 2016年 com.pico. All rights reserved.
//

#import "NSDate+category.h"

@implementation NSDate (category)

+ (NSString *)chindDateFormate:(NSDate *)update{
   
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *destDateString = [dateFormatter stringFromDate:update];
    return destDateString;
}

@end
