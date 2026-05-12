//
//  GamePlayAlert.h
//  TreasureHunter
//
//  Created by  on 12. 6. 13..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MissionItem.h"

@interface GamePlayAlert : UIAlertView<UIAccelerometerDelegate>{
    
    UIAccelerometer *accelerometerManager;
    
    UIButton *homeButton;
    NSTimer *timer;
    
    UIImage *basicImg;
    UIImage *topImg;
    UIImageView *progressView;
    UIImageView *progressTopView;
    UIImageView *modeView;
    
    UIImage *img0;
    UIImage *img1;
    
    MissionItem *missionItem;
    int timeCount;
    int level;
    int type;
    int count;
    BOOL isFirst;
}

@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) UIImage *basicImg;
@property (nonatomic, retain) UIImage *topImg;
@property (nonatomic, retain) UIImage *img0;
@property (nonatomic, retain) UIImage *img1;

- (id) initWithItem:(MissionItem *)getMissionItem
           GameType:(int)getGameType
          GameLevel:(int)getGameLevel;

@end
