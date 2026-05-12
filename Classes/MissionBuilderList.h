//
//  MissionBuilderList.h
//  TreasureHunter
//
//  Created by ejola on 11. 3. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "MissionInPlayDao.h"

@class TreasureHunterAppDelegate;
@class Mission;
@interface MissionBuilderList :  UIViewController <UITableViewDelegate, UITableViewDataSource>{

    UITableView *tableView;
    Mission *uMission;
}

@property(retain, nonatomic) UITableView *tableView;


- (void)btnPlusClick;
- (void)uploadServer:(Mission *)mission;
@end
