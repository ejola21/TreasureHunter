//
//  UserReg.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 8. 20..
//  Copyright 2011 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreasureHunterAppDelegate.h"

@interface UserReg : UIViewController <UITextFieldDelegate,UIAlertViewDelegate>{
    
    IBOutlet UITextField *txtUserID;
    IBOutlet UITextField *txtPassword;
    IBOutlet UITextField *txtRePassword;
    IBOutlet UIButton *btnCreate;
    UILabel *password;
    UILabel *repassword;
    UILabel *email;
    int i;
}
@property (retain, nonatomic) IBOutlet UILabel *password;
@property (retain, nonatomic) IBOutlet UILabel *repassword;
@property (retain, nonatomic) IBOutlet UILabel *email;

@property (nonatomic, retain) IBOutlet UITextField *txtUserID;
@property (nonatomic, retain) IBOutlet UITextField *txtPassword;
@property (nonatomic, retain) IBOutlet UITextField *txtRePassword;
@property (nonatomic, retain) IBOutlet UIButton *btnCreate;

-(IBAction) btnCreateClick:(id)sender;
-(IBAction) btnCancelClick:(id)sender;
-(TreasureHunterAppDelegate *)appDeligate;
-(NSString*) md5:(NSString*)srcStr;

@end
