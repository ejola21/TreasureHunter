//
//  MissionListDetailController.h
//  TreasureHunter
//
//  Created by  on 12. 6. 15..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MissionList.h"
#import "MissionInPlay.h"

@class Mission;
//@class GKLocalPlayer;

@interface MissionListDetailController : UIViewController<UITableViewDelegate,CLLocationManagerDelegate,UITableViewDataSource>
{
    
    UITableView *tableView;
    NSDictionary *missionDic;
    NSMutableString	*missionID;
    NSMutableArray *replyList;
    Mission *mission;
    MissionList *listCaller;
    
    int recommend;
    int play;
    int fail;
    int totalCnt;
    int mandatoryCnt;
    float recommendAvg;
    BOOL isTest;
    BOOL isPlayed;
    UINavigationItem *navigationTitle;
    UINavigationBar *naviBar;
    NSString *mPlayTimeString;
}





@property (retain, nonatomic) IBOutlet UINavigationItem *navigationTitle;
@property(retain, nonatomic) UITableView *tableView;
@property (nonatomic, retain) NSDictionary *missionDic;
@property (nonatomic, retain) Mission *mission;
@property (nonatomic, retain) MissionList *listCaller;

@property (nonatomic) BOOL isTest;
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;

//@property(retain, nonatomic) GKLocalPlayer *localPlayer;

- (NSString *)trimUserID:(NSString*)userId;
- (IBAction)setClickList:(id)sender;
- (IBAction)setClickPlay:(id)sender;
- (void)httpSend:(NSString *) str;
- (void)getMissionReply;
@end
