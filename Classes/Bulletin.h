//
//  Bulletin.h
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class Mission;

@interface Bulletin : UIViewController<UITableViewDelegate, UITableViewDataSource> {
    UITableView *tableView;
    UITableViewCell *tableViewCell;
    

    NSMutableArray *playedImgArray;
    NSMutableArray *designedImgArray;
    UINavigationBar *naviBar;
    IBOutlet UINavigationItem *navigationItem;

}
@property(retain, nonatomic) UITableView *tableView;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;
- (void)httpSend:(int) getKind;
- (BOOL)showBadge:(int)loc badgeKind:(int)kind;
@end
