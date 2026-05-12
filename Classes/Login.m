//
//  Login.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 8. 20..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import "Login.h"
#import "HTTPRequest.h"
#import "UserReg.h"
#import <CommonCrypto/CommonDigest.h>
#define CC_MD5_DIGEST_LENGTH 16

@implementation Login
@synthesize txtUserID;
@synthesize txtPassword;
@synthesize btnLogin;
@synthesize btnReg;
@synthesize listCaller;

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
    
    if(![[APPDEL gUserID] isEqualToString:[APPDEL guestUserID]]){
        [self dismissModalViewControllerAnimated:true];
        if(listCaller != nil){
            [listCaller getList:0];
            [listCaller.segmenteControl setSelectedSegmentIndex:0];
        }
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [txtPassword setSecureTextEntry:YES];
    [txtUserID becomeFirstResponder];
}

-(IBAction) btnLoginClick:(id)sender
{
    [self checkLogin:self.txtUserID.text pwd:self.txtPassword.text];
}
-(IBAction) btnRegClick:(id)sender
{
 	UserReg *userReg = [[[UserReg alloc] init] autorelease];
	[self presentModalViewController:userReg animated:YES];
    
}
-(IBAction) btnCancelClick:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
    
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

-(BOOL)checkLogin:(NSString *)userID pwd:(NSString *)password
{

    // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
    // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"800",       @"tr",
                                userID,           @"user_id", 
                                [self md5:password],           @"password", 
                                nil];
	NSLog(@"bodyObject:%@",bodyObject);
    
	// 통신 완료 후 호출할 델리게이트 셀렉터 설정
	[httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];
	// 페이지 호출
	[httpRequest requestUrl:url bodyObject:bodyObject];
	//[indicator startAnimating];
    
    return YES;
}

- (void)didReceiveFinished:(NSString *)result
{
    
    if ([[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"SUCCESS"]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"success_login", nil)
                                                            message:NSLocalizedString(@"success_login_message", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];    
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"fail_login", nil)
                                                            message:NSLocalizedString(@"fail_login_message", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];    
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  
{ 
    [self appDeligate]. gUserID = txtUserID.text;
    [APPDEL regGUserID:txtUserID.text];
    [self dismissModalViewControllerAnimated:YES];
    if(listCaller != nil){
        [listCaller getList:0];
        [listCaller.segmenteControl setSelectedSegmentIndex:0];
    }
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
    [txtUserID release];
    [txtPassword release];
    [btnLogin release];
    [btnReg release];
    [super dealloc];
}

@end