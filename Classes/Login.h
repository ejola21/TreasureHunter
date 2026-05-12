//
//  Login.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 8. 20..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreasureHunterAppDelegate.h"
#import "MissionList.h"

@interface Login : UIViewController {
    IBOutlet UITextField *txtUserID;
    IBOutlet UITextField *txtPassword;
    IBOutlet UIButton *btnLogin;
    IBOutlet UIButton *btnReg;
    MissionList *listCaller;
}

@property (nonatomic, retain) IBOutlet UITextField *txtUserID;
@property (nonatomic, retain) IBOutlet UITextField *txtPassword;
@property (nonatomic, retain) IBOutlet UIButton *btnLogin;
@property (nonatomic, retain) IBOutlet UIButton *btnReg;
@property (nonatomic, retain) MissionList *listCaller;

-(IBAction) btnLoginClick:(id)sender;
-(IBAction) btnRegClick:(id)sender;
-(IBAction) btnCancelClick:(id)sender;
-(BOOL)checkLogin:(NSString *)userID pwd:(NSString *)password;
-(TreasureHunterAppDelegate *)appDeligate;
-(NSString*) md5:(NSString*)srcStr;
@end
