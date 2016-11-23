//
//  NSString+category.m
//  IAPDemo
//
//  Created by Charles.Yao on 2016/10/31.
//  Copyright © 2016年 com.pico. All rights reserved.
//

#import "NSString+category.h"

@implementation NSString (category)

+ (NSString *)uuid{
    // create a new UUID which you own
    CFUUIDRef uuidref = CFUUIDCreate(kCFAllocatorDefault);
    
    // create a new CFStringRef (toll-free bridged to NSString)
    // that you own
    CFStringRef uuid = CFUUIDCreateString(kCFAllocatorDefault, uuidref);
    
    NSString *result = (__bridge NSString *)uuid;
    //release the uuidref
    CFRelease(uuidref);
    // release the UUID
    CFRelease(uuid);
    
    return result;
}

@end
