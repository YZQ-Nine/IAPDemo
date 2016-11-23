//
//  IAPManager.m
//  IAPDemo
//
//  Created by Charles.Yao on 2016/10/31.
//  Copyright © 2016年 com.pico. All rights reserved.
//

#import "IAPManager.h"

static NSString * const receiptKey = @"receipt_key";
static NSString * const dateKey = @"date_key";
static NSString * const userIdKey = @"userId_key";

@interface IAPManager ()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (nonatomic, assign) BOOL goodsRequestFinished; //判断一次请求是否完成

@property (nonatomic, copy) NSString *receipt; //交易成功后拿到的一个64编码字符串

@property (nonatomic, copy) NSString *date; //交易时间

@property (nonatomic, copy) NSString *userId; //交易人

@end

@implementation IAPManager

singleton_implementation(IAPManager)

- (void)startManager { //开启监听

    self.goodsRequestFinished = YES;

    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)stopManager{

    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark 查询
- (void)requestProductWithId:(NSString *)productId {

    if (self.goodsRequestFinished) {
       
        if ([SKPaymentQueue canMakePayments]) { //用户允许app内购
            
            if (productId.length) {
               
                NSLog(@"%@商品正在请求中",productId);
               
                self.goodsRequestFinished = NO; //正在请求
               
                NSArray *product = [[NSArray alloc] initWithObjects:productId, nil];
                
                NSSet *set = [NSSet setWithArray:product];
               
                SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
               
                productRequest.delegate = self;
               
                [productRequest start];
            
            } else {
               
                NSLog(@"商品为空");
                
                [self filedWithErrorCode:IAP_FILEDCOED_EMPTYGOODS error:nil];
                
                self.goodsRequestFinished = YES; //完成请求
            }
        
        } else { //没有权限
            
            [self filedWithErrorCode:IAP_FILEDCOED_NORIGHT error:nil];
            
            self.goodsRequestFinished = YES; //完成请求
        }
    
    } else {

        NSLog(@"上次请求还未完成，请稍等");
    }
}

#pragma mark SKProductsRequestDelegate 查询成功后的回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    NSArray *product = response.products;
    
    if (product.count == 0) {
        
        NSLog(@"无法获取商品信息，请重试");
        
        [self filedWithErrorCode:IAP_FILEDCOED_CANNOTGETINFORMATION error:nil];
        
        self.goodsRequestFinished = YES; //失败，请求完成

    } else {
        //发起购买请求
        SKPayment *payment = [SKPayment paymentWithProduct:product[0]];
       
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark SKProductsRequestDelegate 查询失败后的回调
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    [self filedWithErrorCode:IAP_FILEDCOED_APPLECODE error:[error localizedDescription]];
    
    self.goodsRequestFinished = YES; //失败，请求完成
}

#pragma Mark 购买操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
       
        switch (transaction.transactionState) {
           
            case SKPaymentTransactionStatePurchasing://正在交易
               
                break;

            case SKPaymentTransactionStatePurchased://交易完成
                
                [self getReceipt]; //获取交易成功后的购买凭证
               
                [self saveReceipt]; //存储交易凭证
               
                [self sendIAPFiles];//把self.receipt发送到服务器验证是否有效
                
                [self completeTransaction:transaction];
                
                break;

            case SKPaymentTransactionStateFailed://交易失败
               
                [self failedTransaction:transaction];
                
                break;

            case SKPaymentTransactionStateRestored://已经购买过该商品
                
                [self restoreTransaction:transaction];
                
                break;
           
            default:
               
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    self.goodsRequestFinished = YES; //成功，请求完成
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction {

    NSLog(@"transaction.error.code = %ld", transaction.error.code);

    if(transaction.error.code != SKErrorPaymentCancelled) {

        [self filedWithErrorCode:IAP_FILEDCOED_BUYFILED error:nil];

    } else {

        [self filedWithErrorCode:IAP_FILEDCOED_USERCANCEL error:nil];
    }

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
   
    self.goodsRequestFinished = YES; //失败，请求完成

}


- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    self.goodsRequestFinished = YES; //恢复购买，请求完成

}

#pragma mark 向服务器端验证购买凭证的有效性

- (void)getReceipt {

    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptUrl];
   
    self.receipt = [receiptData base64EncodedStringWithOptions:0];
}

#pragma mark  持久化存储用户购买凭证(这里最好还要存储当前日期，用户id等信息，用于区分不同的凭证)
-(void)saveReceipt {

    self.date = [NSDate chindDateFormate:[NSDate date]];
    
    NSString *fileName = [NSString uuid];
   
    self.userId = @"UserID";
   
    NSString *savedPath = [NSString stringWithFormat:@"%@%@.plist", [SandBoxHelper iapReceiptPath], fileName];
    
    NSDictionary *dic =[NSDictionary dictionaryWithObjectsAndKeys:
                        self.receipt,                           receiptKey,
                        self.date,                              dateKey,
                        self.userId,                            userIdKey,
                        nil];
   
    NSLog(@"%@",savedPath);
    
    [dic writeToFile:savedPath atomically:YES];
}

#pragma mark 将存储到本地的IAP文件发送给服务端 验证receipt失败,App启动后再次验证
- (void)sendIAPFiles{

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
   
    //搜索该目录下的所有文件和目录
    NSArray *cacheFileNameArray = [fileManager contentsOfDirectoryAtPath:[SandBoxHelper iapReceiptPath] error:&error];
    
    if (error == nil) {
       
        for (NSString *name in cacheFileNameArray) {
            
            if ([name hasSuffix:@".plist"]){ //如果有plist后缀的文件，说明就是存储的购买凭证
               
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", [SandBoxHelper iapReceiptPath], name];
                
                [self sendAppStoreRequestBuyPlist:filePath];
            }
        }
    
    } else {
       
        NSLog(@"AppStoreInfoLocalFilePath error:%@", [error domain]);
    }
}

-(void)sendAppStoreRequestBuyPlist:(NSString *)plistPath {

    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    //这里的参数请根据自己公司后台服务器接口定制，但是必须发送的是持久化保存购买凭证
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [dic objectForKey:receiptKey],          receiptKey,
                                   [dic objectForKey:dateKey],             dateKey,
                                   [dic objectForKey:userIdKey],           userIdKey,
                                   nil];

#warning 在这里将凭证发送给服务器
    
    if(@"凭证有效"){
        
        [self removeReceipt];
    
    } else {//凭证无效
        
        //做你想做的
    }
}



//验证成功就从plist中移除凭证
-(void)removeReceipt{
   
    NSFileManager *fileManager = [NSFileManager defaultManager];
   
    if ([fileManager fileExistsAtPath:[SandBoxHelper iapReceiptPath]]) {
        
        [fileManager removeItemAtPath:[SandBoxHelper iapReceiptPath] error:nil];
    
    }
}


#pragma mark 错误信息反馈
- (void)filedWithErrorCode:(NSInteger)code error:(NSString *)error {

    if (self.delegate && [self.delegate respondsToSelector:@selector(filedWithErrorCode:andError:)]) {
        switch (code) {
            case IAP_FILEDCOED_APPLECODE:
                [self.delegate filedWithErrorCode:IAP_FILEDCOED_APPLECODE andError:error];
                break;

                case IAP_FILEDCOED_NORIGHT:
                [self.delegate filedWithErrorCode:IAP_FILEDCOED_NORIGHT andError:nil];
                break;

            case IAP_FILEDCOED_EMPTYGOODS:
                [self.delegate filedWithErrorCode:IAP_FILEDCOED_EMPTYGOODS andError:nil];
                break;

            case IAP_FILEDCOED_CANNOTGETINFORMATION:
                 [self.delegate filedWithErrorCode:IAP_FILEDCOED_CANNOTGETINFORMATION andError:nil];
                break;

            case IAP_FILEDCOED_BUYFILED:
                 [self.delegate filedWithErrorCode:IAP_FILEDCOED_BUYFILED andError:nil];
                break;

            case IAP_FILEDCOED_USERCANCEL:
                 [self.delegate filedWithErrorCode:IAP_FILEDCOED_USERCANCEL andError:nil];
                break;

            default:
                break;
        }
    }
}

#pragma mark 启动判断是否漏单
- (void)validationLastTrade {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    //从服务器验证receipt失败之后，在程序再次启动的时候，使用保存的receipt再次到服务器验证
    if (![fileManager fileExistsAtPath:[SandBoxHelper iapReceiptPath]]) {//如果在该路下不存在文件，说明就没有保存验证失败后的购买凭证，也就是说发送凭证成功。

    } else { //存在购买凭证，说明发送凭证失败，再次发起验证
        
        [self sendIAPFiles];
    }
}


@end
