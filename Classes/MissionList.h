//
//  Bulletin.h
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MissionList : UIViewController<UITableViewDelegate, UITableViewDataSource> {
    UITableView *tableView;
    UITableViewCell *tableViewCell;
    
	NSMutableArray *missions;
    NSMutableArray *gameList;
    NSArray *imgArray;
    UINavigationBar *naviBar;
    BOOL getMyList;
    int tabKind;
    int last;
    int playCount;
    IBOutlet UISegmentedControl *segmenteControl;
}
@property(retain, nonatomic) UITableView *tableView;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmenteControl;
@property (retain, nonatomic) IBOutlet UINavigationBar *naviBar;

//- (void)httpSend:(int) trNumber;
- (void)didReceiveFinished:(NSString *)result;
- (IBAction)segmentedChange:(id)sender;
- (void)playedHttpSend;
- (void)playingHttpSend;
- (void)listHttpSend:(int) trNumber;
- (void)getList:(int) kind;

@end
