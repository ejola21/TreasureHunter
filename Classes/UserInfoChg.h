//
//  UserInfoChg.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 9. 8..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreasureHunterAppDelegate.h"

@interface UserInfoChg : UIViewController<UITextFieldDelegate> {
  IBOutlet UIScrollView *uiScrollView;
  CGPoint svos;
  
  IBOutlet UITextField *txtPassword;
  IBOutlet UITextField *txtEmailAddr;
  IBOutlet UITextField *txtPhoneNo;
  IBOutlet UIButton *btnChange;
  int i;
}

@property (nonatomic, retain)  IBOutlet UIScrollView *uiScrollView;
@property (nonatomic, retain) IBOutlet UITextField *txtPassword;
@property (nonatomic, retain) IBOutlet UITextField *txtEmailAddr;
@property (nonatomic, retain) IBOutlet UITextField *txtPhoneNo;
@property (nonatomic, retain) IBOutlet UIButton *btnChange;

-(IBAction) btnChangeClick:(id)sender;
-(IBAction) btnCancelClick:(id)sender;
-(TreasureHunterAppDelegate *)appDeligate;
-(NSString*) md5:(NSString*)srcStr;

@end
