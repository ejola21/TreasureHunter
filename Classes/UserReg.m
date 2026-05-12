//
//  UserReg.m
//  TreasureHunter
//
//  Created by 인상 이 on 11. 8. 20..
//  Copyright 2011. All rights reserved.
//

#import "UserReg.h"
#import "HTTPRequest.h"
#import <CommonCrypto/CommonDigest.h>
#define CC_MD5_DIGEST_LENGTH 16

@implementation UserReg
@synthesize password;
@synthesize repassword;
@synthesize email;
@synthesize txtUserID;
@synthesize txtPassword;
@synthesize txtRePassword;
@synthesize btnCreate;

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
    [txtPassword setSecureTextEntry:YES];
    [txtRePassword setSecureTextEntry:YES];
    [txtUserID becomeFirstResponder];
    
    txtUserID.delegate = self;
    txtPassword.delegate = self;
    txtRePassword.delegate = self;
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.returnKeyType == UIReturnKeyDone)
	{
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

- (BOOL)isValidEmail:(NSString *)inputText
{
    NSString *emailRegex = @"[A-Z0-9a-z][A-Z0-9a-z._%+-]*@[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z]{2,6}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    NSRange dotRange;
    NSRange atRange;
    
    BOOL isValidDomain = NO;
    BOOL isValidSite = NO;
    
    if([emailTest evaluateWithObject:inputText]) 
    {
        dotRange = [inputText rangeOfString:@"." options:NSBackwardsSearch range:NSMakeRange(0, [inputText length])];
        int indexOfDot = dotRange.location;
        
        if(dotRange.location != NSNotFound) 
        {
            NSString *topLevelDomain = [inputText substringFromIndex:indexOfDot];
            topLevelDomain = [topLevelDomain lowercaseString];
            NSSet *TLD;
            TLD = [NSSet setWithObjects:@".aero", @".asia", @".biz", @".cat", @".com", @".coop", @".edu", @".gov", @".info", @".int", @".jobs", @".mil", @".mobi", @".museum", @".name", @".net", @".org", @".pro", @".tel", @".travel", @".ac", @".ad", @".ae", @".af", @".ag", @".ai", @".al", @".am", @".an", @".ao", @".aq", @".ar", @".as", @".at", @".au", @".aw", @".ax", @".az", @".ba", @".bb", @".bd", @".be", @".bf", @".bg", @".bh", @".bi", @".bj", @".bm", @".bn", @".bo", @".br", @".bs", @".bt", @".bv", @".bw", @".by", @".bz", @".ca", @".cc", @".cd", @".cf", @".cg", @".ch", @".ci", @".ck", @".cl", @".cm", @".cn", @".co", @".cr", @".cu", @".cv", @".cx", @".cy", @".cz", @".de", @".dj", @".dk", @".dm", @".do", @".dz", @".ec", @".ee", @".eg", @".er", @".es", @".et", @".eu", @".fi", @".fj", @".fk", @".fm", @".fo", @".fr", @".ga", @".gb", @".gd", @".ge", @".gf", @".gg", @".gh", @".gi", @".gl", @".gm", @".gn", @".gp", @".gq", @".gr", @".gs", @".gt", @".gu", @".gw", @".gy", @".hk", @".hm", @".hn", @".hr", @".ht", @".hu", @".id", @".ie", @" No", @".il", @".im", @".in", @".io", @".iq", @".ir", @".is", @".it", @".je", @".jm", @".jo", @".jp", @".ke", @".kg", @".kh", @".ki", @".km", @".kn", @".kp", @".kr", @".kw", @".ky", @".kz", @".la", @".lb", @".lc", @".li", @".lk", @".lr", @".ls", @".lt", @".lu", @".lv", @".ly", @".ma", @".mc", @".md", @".me", @".mg", @".mh", @".mk", @".ml", @".mm", @".mn", @".mo", @".mp", @".mq", @".mr", @".ms", @".mt", @".mu", @".mv", @".mw", @".mx", @".my", @".mz", @".na", @".nc", @".ne", @".nf", @".ng", @".ni", @".nl", @".no", @".np", @".nr", @".nu", @".nz", @".om", @".pa", @".pe", @".pf", @".pg", @".ph", @".pk", @".pl", @".pm", @".pn", @".pr", @".ps", @".pt", @".pw", @".py", @".qa", @".re", @".ro", @".rs", @".ru", @".rw", @".sa", @".sb", @".sc", @".sd", @".se", @".sg", @".sh", @".si", @".sj", @".sk", @".sl", @".sm", @".sn", @".so", @".sr", @".st", @".su", @".sv", @".sy", @".sz", @".tc", @".td", @".tf", @".tg", @".th", @".tj", @".tk", @".tl", @".tm", @".tn", @".to", @".tp", @".tr", @".tt", @".tv", @".tw", @".tz", @".ua", @".ug", @".uk", @".us", @".uy", @".uz", @".va", @".vc", @".ve", @".vg", @".vi", @".vn", @".vu", @".wf", @".ws", @".ye", @".yt", @".za", @".zm", @".zw", nil];
            if(topLevelDomain != nil && ([TLD containsObject:topLevelDomain])) 
            {
                isValidDomain = YES;
            }
        }
        atRange = [inputText rangeOfString:@"@" options:NSBackwardsSearch range:NSMakeRange(0, [inputText length])];
        int indexOfAt = atRange.location;
        
        if(atRange.location != NSNotFound)
        {
            NSString *topLevelSite = [inputText substringWithRange:NSMakeRange(indexOfAt, indexOfDot - indexOfAt)];
            topLevelSite = [topLevelSite lowercaseString];
            isValidSite = YES;
            /*
            NSSet *TLS;
            //Add your required domain names to the set below
            TLS = [NSSet setWithObjects:@"@google", @"@yahoo", nil];
            
            if(topLevelSite != nil && ([TLS containsObject:topLevelSite])) 
            {
                isValidSite = YES;
            }
             */
        }
        
    }
    return (isValidDomain && isValidSite);
}

-(IBAction) btnCreateClick:(id)sender
{
    if (![self isValidEmail:txtUserID.text]) {
        
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_reg_8", nil)
                                                            message:NSLocalizedString(@"user_reg_1", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        [txtUserID becomeFirstResponder];
        return;
    }
    
    if ([txtPassword.text length] < 5) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_reg_0", nil)
                                                            message:NSLocalizedString(@"user_reg_2", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        [txtPassword becomeFirstResponder];
        return;
    }
    
    if ([txtPassword.text isEqualToString:txtRePassword.text] != YES) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_reg_3", nil)
                                                            message:NSLocalizedString(@"user_reg_4", nil)
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        [txtPassword becomeFirstResponder];
        return;
    }
    
    // 접속할 주소 설정
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	//NSString *url = @"http://mking.elogin.co.kr/xe/user.php";
	// HTTP Request 인스턴스 생성
	HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
	// POST로 전송할 데이터 설정  
    // Dictionay 특성 조심 nil 이면 다음 항목 전송 안딤
	NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"tr_user_reg", @"tr",
                                txtUserID.text, @"user_id", 
                                [self md5:txtPassword.text], @"password",nil];
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
    
    if ([[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@"SUCCESS"]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_reg_6", nil) 
                                                            message:NSLocalizedString(@"user_reg_7", nil)
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil) 
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];    
      
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_reg_5", nil)
                                                            message:result
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
    NSLog(@"%@",txtUserID.text);
    [APPDEL regGUserID:txtUserID.text];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setEmail:nil];
    [self setPassword:nil];
    [self setRepassword:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [txtUserID release];
    [txtPassword release];
    [txtRePassword release];
    [btnCreate release];
    [email release];
    [password release];
    [repassword release];
    [super dealloc];
}

@end
