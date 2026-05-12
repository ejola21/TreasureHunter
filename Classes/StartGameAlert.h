//
//  StartGameAlert.h
//  TreasureHunter
//
//  Created by  on 12. 7. 16..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TreasureHunterAppDelegate.h"

@interface StartGameAlert :  UIAlertView{
    UIImage *backgroundImage;
    UILabel *titleLabel;
    UISegmentedControl *segControl;
    
    UIButton *btnLeft;
    UIButton *btnRight;
    UIButton *btnBack;
    BOOL isVirtural;
}

@property(readwrite, retain) UIImage *backgroundImage;
@property(nonatomic, assign) BOOL isVirtural;


- (id) initWithKind:(int)kind;


@end
