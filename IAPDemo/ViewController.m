//
//  ViewController.m
//  IAPDemo
//
//  Created by Charles.Yao on 2016/10/31.
//  Copyright © 2016年 com.pico. All rights reserved.
//

#import "ViewController.h"

static NSString * const productId = @"com.picovr.picovr.test.0001";

@interface ViewController ()<IApRequestResultsDelegate>

@property (nonatomic, strong) UIButton *payBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [IAPManager shared].delegate = self;
    
    [self layoutSetting];
  
}

- (void)layoutSetting {
    
    self.view.backgroundColor = [UIColor cyanColor];
    
    self.payBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.payBtn.frame = CGRectMake(0, 0, 200, 50);
    self.payBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    [self.payBtn setTitle:@"购买" forState:UIControlStateNormal];
    [self.payBtn setTintColor:[UIColor blackColor]];
    self.payBtn.layer.masksToBounds = YES;
    self.payBtn.layer.cornerRadius = 5;
    self.payBtn.layer.borderWidth = 1;
    self.payBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [self.view addSubview:self.payBtn];
    
    [self.payBtn addTarget:self action:@selector(payClick) forControlEvents:UIControlEventTouchUpInside];
    
}

#pragma mark 购买行为
- (void)payClick {

    [[IAPManager shared] requestProductWithId:productId];
    
}

#pragma mark IApRequestResultsDelegate
- (void)filedWithErrorCode:(NSInteger)errorCode andError:(NSString *)error {

    switch (errorCode) {
        case IAP_FILEDCOED_APPLECODE:
            NSLog(@"用户禁止应用内付费购买:%@",error);
            break;

        case IAP_FILEDCOED_NORIGHT:
            NSLog(@"用户禁止应用内付费购买");
            break;

        case IAP_FILEDCOED_EMPTYGOODS:
            NSLog(@"商品为空");
            break;

        case IAP_FILEDCOED_CANNOTGETINFORMATION:
            NSLog(@"无法获取产品信息，请重试");
            break;

        case IAP_FILEDCOED_BUYFILED: 
            NSLog(@"购买失败，请重试");
            break;

        case IAP_FILEDCOED_USERCANCEL:
            NSLog(@"用户取消交易");
            break;
            
        default:
            break;
    }
}




@end
