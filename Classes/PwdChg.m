//
//  PwdChg.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 9. 4..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "PwdChg.h"
#import "HTTPRequest.h"
#import <CommonCrypto/CommonDigest.h>
#define CC_MD5_DIGEST_LENGTH 16


@implementation PwdChg

@synthesize uiScrollView;
@synthesize txtOldPassword;
@synthesize txtNewPassword;
@synthesize txtRePassword;
@synthesize btnChange;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
 // Custom initialization
 }
 return self;
 }
 */

-(TreasureHunterAppDelegate *)appDeligate
{
	return (TreasureHunterAppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)viewDidAppear:(BOOL)animated   
{
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  [txtOldPassword setSecureTextEntry:YES];
  [txtNewPassword setSecureTextEntry:YES];
  [txtRePassword setSecureTextEntry:YES];
  [txtOldPassword becomeFirstResponder];
  
  txtOldPassword.delegate = self;
  txtNewPassword.delegate = self;
  txtRePassword.delegate = self;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	svos = uiScrollView.contentOffset;
	CGPoint pt;
	CGRect rc = [textField bounds];
	rc = [textField convertRect:rc toView:uiScrollView];
	pt = rc.origin;
	pt.x = 0;
	pt.y -= 56;
	[uiScrollView setContentOffset:pt animated:YES];           
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.returnKeyType == UIReturnKeyDone)
	{
    [uiScrollView setContentOffset:svos animated:YES]; 
		[textField resignFirstResponder];
	}
	return YES;
}

-(NSString*) md5:(NSString*)srcStr
{
	const char *cStr = [srcStr UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cStr, strlen(cStr), result);
	return [[NSString stringWithFormat:
           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
           result[0],result[1],result[2],result[3],result[4],result[5],result[6],result[7],
           result[8],result[9],result[10],result[11],result[12],result[13],result[14],result[15]] lowercaseString];
}

-(IBAction) btnCancelClick:(id)sender
{
  [self dismissModalViewControllerAnimated:YES];
}

-(IBAction) btnChangeClick:(id)sender
{
  if ([txtOldPassword.text isEqualToString:@""]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pwd_0", nil) 
                                                        message:NSLocalizedString(@"pwd_1", nil)
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [txtOldPassword becomeFirstResponder];
    return;
  }
  
  if ([txtNewPassword.text isEqualToString:@""]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pwd_0", nil)
                                                        message:NSLocalizedString(@"pwd_2", nil)
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [txtNewPassword becomeFirstResponder];
    return;
  }
  
  if ([txtNewPassword.text isEqualToString:txtRePassword.text] != YES) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pwd_3", nil)
                                                        message:NSLocalizedString(@"pwd_4", nil) 
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [txtNewPassword becomeFirstResponder];
    return;
  }
  
	[uiScrollView setContentOffset:svos animated:YES]; 
  
  // 접속할 주소 설정
	//NSString *url = @"http://mking.elogin.co.kr/xe/user.php";
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/user.php"] autorelease];
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
  // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"tr_pwd_chg",       @"tr",
															[APPDEL gUserID],           @"user_id", 
															[self md5:txtOldPassword.text],           @"old_password", 
															[self md5:txtNewPassword.text],           @"new_password", 
															nil];
	NSLog(@"bodyObject:%@",bodyObject);
  
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
}

- (void)didReceiveFinished:(NSString *)result
{
  NSLog(@"result:%@:",result);
  if ([[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"SUCCESS"]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pwd_5", nil)
                                                        message:NSLocalizedString(@"pwd_6", nil)
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
  }
  else {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"pwd_7", nil)
                                                        message:NSLocalizedString(@"pwd_8", nil) 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  
{ 
  [self dismissModalViewControllerAnimated:YES];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [uiScrollView release];
  [txtOldPassword release];
  [txtNewPassword release];
  [txtRePassword release];
  [btnChange release];
  [super dealloc];
}

@end
