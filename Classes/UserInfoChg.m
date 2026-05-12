//
//  UserInfoChg.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 9. 8..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "UserInfoChg.h"

#import "HTTPRequest.h"
#import <CommonCrypto/CommonDigest.h>
#define CC_MD5_DIGEST_LENGTH 16

@implementation UserInfoChg
@synthesize uiScrollView;
@synthesize txtPassword;
@synthesize txtEmailAddr;
@synthesize txtPhoneNo;
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
  // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://mking.elogin.co.kr/xe/user.php"] autorelease];
	//NSString *url = @"http://mking.elogin.co.kr/xe/user.php";
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
  // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"tr_user_sel",       @"tr",
															[APPDEL gUserID],           @"user_id", 
															nil];
	NSLog(@"bodyObject:%@",bodyObject);
  
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didSelReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
  [txtPassword setSecureTextEntry:YES];
  [txtPassword becomeFirstResponder];
  
  txtPassword.delegate = self;
  txtEmailAddr.delegate = self;
  txtPhoneNo.delegate = self;
  
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
  if ([txtPassword.text isEqualToString:@""]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"필수항목 입력오류!" 
                                                        message:@"Password를 입력하세요." 
                                                       delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [txtPassword becomeFirstResponder];
    return;
  }
  
	[uiScrollView setContentOffset:svos animated:YES]; 
  
  // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://mking.elogin.co.kr/xe/user.php"] autorelease];
	//NSString *url = @"http://mking.elogin.co.kr/xe/user.php";
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
  // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"tr_user_chg",       @"tr",
															[APPDEL gUserID],           @"user_id", 
															[self md5:txtPassword.text],           @"password", 
															txtEmailAddr.text,           @"email_addr", 
															txtPhoneNo.text,           @"phone_no", 
															nil];
	NSLog(@"bodyObject:%@",bodyObject);
  
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
}

- (void)didSelReceiveFinished:(NSString *)result
{
  NSLog(@"result:%@:",result);
  if (![result isEqualToString:@" ERROR"]) {
  }
  else {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"회원정보 조회오류!" 
                                                        message:@"나중에 다시 시도하세요." 
                                                       delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
  }
}

- (void)didReceiveFinished:(NSString *)result
{
  NSLog(@"result:%@:",result);
  if (![result isEqualToString:@" SUCCESS"]) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"회원정보변경 오류!" 
                                                        message:@"나중에 다시 시도하세요." 
                                                       delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alertView show];
    [alertView release];    
  }
  else {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"회원정보변경 완료!" 
                                                        message:@"계속 플레이하세요." 
                                                       delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
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
  [txtPassword release];
  [txtEmailAddr release];
  [txtPhoneNo release];
  [btnChange release];
  [super dealloc];
}

@end
