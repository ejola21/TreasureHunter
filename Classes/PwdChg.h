//
//  PwdChg.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 9. 4..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreasureHunterAppDelegate.h"


@interface PwdChg : UIViewController  <UITextFieldDelegate,UIAlertViewDelegate>{
  IBOutlet UIScrollView *uiScrollView;
  CGPoint svos;
  
  IBOutlet UITextField *txtOldPassword;
  IBOutlet UITextField *txtNewPassword;
  IBOutlet UITextField *txtRePassword;
  IBOutlet UIButton *btnChange;
  int i;
}

@property (nonatomic, retain)  IBOutlet UIScrollView *uiScrollView;
@property (nonatomic, retain) IBOutlet UITextField *txtOldPassword;
@property (nonatomic, retain) IBOutlet UITextField *txtNewPassword;
@property (nonatomic, retain) IBOutlet UITextField *txtRePassword;
@property (nonatomic, retain) IBOutlet UIButton *btnChange;

-(IBAction) btnChangeClick:(id)sender;
-(IBAction) btnCancelClick:(id)sender;
-(TreasureHunterAppDelegate *)appDeligate;
-(NSString*) md5:(NSString*)srcStr;

@end
