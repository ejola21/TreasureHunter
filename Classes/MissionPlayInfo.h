//
//  MissionPlayInfo.h
//  TreasureHunter
//
//  Created by ejola on 11. 6. 12..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MissionPlay.h"

@interface MissionPlayInfo : UITableViewController 
{
	NSMutableArray	*tableList;
	NSMutableString *missionID;
    MissionPlay *caller;
}

@property (nonatomic, retain) NSMutableString *missionID;
@property (nonatomic, retain) MissionPlay *caller;
- (void)makeTableList;


@end
