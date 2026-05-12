//
//  Setting.h
//  TreasureHunter
//
//  Created by 노지연 on 12. 2. 8..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MRScrollView.h"
#import "MissionListDetailController.h"


@interface Setting :  UIViewController <UIScrollViewDelegate,UITableViewDelegate, UITableViewDataSource>
{
    UINavigationItem *navigationTitle;
    UINavigationBar *naviBar;
    IBOutlet UISegmentedControl *segment;
    UITableView *tableView;
    UITableViewCell *tableViewCell;
    NSMutableArray *tutorialArray;
    NSArray *nameArray;
    UIImageView *imgView;
    int location;
    
}
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollview;
@property (retain, nonatomic) IBOutlet UIButton *btnTitle;
@property (retain, nonatomic) IBOutlet UIButton *btnRight;
@property (retain, nonatomic) IBOutlet UIButton *btnLeft;


- (IBAction)segmentClick:(id)sender;
- (IBAction)infoClick:(id)sender;
- (IBAction)btnRightClick:(id)sender;
- (IBAction)btnLeftClick:(id)sender;
- (void)setClickBtns:(int)kind;

@end
