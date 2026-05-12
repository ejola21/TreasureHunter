//
//  MyInfo.h
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface MyInfo :  UIViewController <UITableViewDelegate, UITableViewDataSource, SKPaymentTransactionObserver, SKProductsRequestDelegate>  {
    UITableView *tableView;
    UITableViewCell *tableViewCell;
    
	NSMutableArray *missions;

    IBOutlet UINavigationItem *navigationItem;
    IBOutlet UINavigationBar *naviBar;
    BOOL onBuy;
    BOOL timeBuy;
}

@property(retain, nonatomic) UITableView *tableView;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;

- (void)httpSend:(int) getKind;
- (void)didReceiveFinished:(NSString *)result;
- (void)didReceivePlayFinished:(NSString *)result;
@end
