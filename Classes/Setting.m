//
//  Setting.m
//  TreasureHunter
//
//  Created by 노지연 on 12. 2. 8..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "Setting.h"
#import "TreasureHunterAppDelegate.h"
#import "SVProgressHUD.h"
#import "JSON.h"
#import "HTTPRequest.h"
#import "DLStarRatingControl.h"
#import "Login.h"

@implementation Setting
@synthesize scrollview;
@synthesize btnTitle;
@synthesize btnRight;
@synthesize btnLeft;
@synthesize naviBar;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    tutorialArray = [[NSMutableArray alloc] init];
    
    CGRect tableViewFrame = CGRectMake(0.0, 44.0, self.view.bounds.size.width, self.view.bounds.size.height - 44 );
    tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.naviBar setTintColor:[APPDEL backColor]];
    
    [segment setTitle:NSLocalizedString(@"setting_title0", nil) forSegmentAtIndex:0];
    [segment setTitle:NSLocalizedString(@"setting_title1", nil) forSegmentAtIndex:1];
    [self.btnTitle setTitle:NSLocalizedString(@"setting_title0", nil) forState:UIControlStateNormal];
    
    [self.view addSubview:tableView];
    self.scrollview.alpha = 0;
    NSString *lang = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    
    if ([lang isEqualToString:@"ko"]) {
        nameArray = [[NSArray alloc] initWithObjects:@"tutorial1.jpg", @"tutorial0.jpg",@"tutorial2.jpg", nil];
    } 
    else {
        nameArray = [[NSArray alloc] initWithObjects:@"tutorial1_en.jpg", @"tutorial0_en.jpg",@"tutorial2_en.jpg", nil];
    }
    
    
    location = 0;
    
    imgView = [[UIImageView alloc] init];
    [self setClickBtns:0];
    [self.scrollview addSubview:imgView];
    [imgView release];
    
}

- (void)viewWillAppear:(BOOL)animated{
    if([tutorialArray count] == 0){
        [self listHttpSend];
    }else{
        [tableView reloadData];
    }
    
}

- (void)setClickBtns:(int)kind{
    if(kind == 1 && location > 0){
        location--;
    }else if(kind == 2 && location < 2){
        location ++;
    }
    if(location == 0){
        self.btnLeft.alpha = 0;
        self.btnRight.alpha = 1;
    }else if(location == 2){
        self.btnLeft.alpha = 1;
        self.btnRight.alpha = 0;
    }else{
        self.btnLeft.alpha = 1;
        self.btnRight.alpha = 1;
    }
    
    
    UIImage* imageBG = [UIImage imageNamed:[nameArray objectAtIndex:location] ];
    [imgView setFrame:CGRectMake(0, 0, 320, imageBG.size.height)];
    [imgView setImage:imageBG];
    self.scrollview.contentSize = CGSizeMake(320,imageBG.size.height);
    [scrollview setContentOffset:CGPointMake(0, 0) animated:false];
}

- (void)viewDidUnload
{
    [self setNaviBar:nil];
    [segment release];
    segment = nil;
    [self setScrollview:nil];
    [self setBtnTitle:nil];
    [self setBtnRight:nil];
    [self setBtnLeft:nil];
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [imgView release]; imgView = nil;
    [navigationTitle release];
    [naviBar release];
    [segment release];
    [scrollview release];
    [btnTitle release];
    [btnRight release];
    [btnLeft release];
    [super dealloc];
}

#pragma mark -
#pragma mark HTTP Functions

- (void)listHttpSend
{
    [self loadingStart];
    
    NSString *gbString = @"1%";
    if([[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0] isEqualToString:@"ko"]){
        gbString = @"0%";
    }
    
    HTTPRequest *httpRequest = [[[HTTPRequest alloc] init] autorelease];
    NSDictionary *bodyObject = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"503",@"tr",
                                gbString, @"gb",
                                nil];
    
    [httpRequest setDelegate:self selector:@selector(didReceiveFinished:)];   
	NSURL *url = [[[NSURL alloc] initWithString:@"http://nexapp.co.kr/playspot/J_MyList.php"] autorelease];
	[httpRequest requestUrl:url bodyObject:bodyObject];
}



- (void)didReceiveFinished:(NSString *)result
{
    if (![result isEqualToString:@"FAIL"])
    {
        SBJsonParser *jsonParser = [[[SBJsonParser alloc] init] autorelease];
        NSArray *svrArr = (NSArray *)[jsonParser objectWithString:result error:NULL];
        [tutorialArray removeAllObjects];
        if(svrArr !=nil){
            [tutorialArray addObjectsFromArray:svrArr]; 
        }
    }
    [tableView reloadData];
    [self loadingFinish];
}


- (void)loadingStart{
    [SVProgressHUD showWithStatus:@"Loading.."];
    segment.userInteractionEnabled = false;
    tableView.userInteractionEnabled = false;
    
}

- (void)loadingFinish{
    segment.userInteractionEnabled = true;
    tableView.userInteractionEnabled = true;
    [SVProgressHUD dismiss];
}

#pragma mark -
#pragma mark TableView Functions



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [tutorialArray count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int row = indexPath.row;
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"MissionListCell" owner:self options:nil] objectAtIndex:0];
    }
    
    
    [cell setBackgroundColor:[APPDEL cellColor]];
    
    DLStarRatingControl *customNumberOfStars = [[[DLStarRatingControl alloc] initWithFrame:CGRectMake(0, 0, 90, 25) andStars:5 isFractional:true setSize0to20:13 clickEnabled:false] autorelease];
    customNumberOfStars.rating = 2.5;
    
    UIView *starView = (UIView *)[cell viewWithTag:100];
    [starView addSubview:customNumberOfStars];
    
    if(row < [tutorialArray count]){
        NSDictionary *dic = [tutorialArray objectAtIndex:row];
        
        customNumberOfStars.rating = [[dic objectForKey:@"RecommendAvg"] floatValue];
        
        UILabel *label;
        label = (UILabel *)[cell viewWithTag:200];
        label.text = [dic objectForKey:@"Title"];
        
        label = (UILabel *)[cell viewWithTag:201];
        label.text = [dic objectForKey:@"Description"];
        
        label = (UILabel *)[cell viewWithTag:202];
        label.text = [dic objectForKey:@"Place"];
        
        label = (UILabel *)[cell viewWithTag:203];
        label.text = [NSString stringWithFormat:@"Play(%@) Fail(%@)", [dic objectForKey:@"PlayCnt"], [dic objectForKey:@"FailCnt"]];
        
        
        UIButton *button = (UIButton *)[cell viewWithTag:300];
        
        UIImage *img = [[APPDEL playedImg] objectForKey:[dic objectForKey:@"MissionID"]];
        
        if(img == nil){
            img = [UIImage imageNamed:@"empty02.png"];
        }
        
        [button setBackgroundImage:img forState:UIControlStateNormal];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
    int row = newIndexPath.row;
    if(row < [tutorialArray count]){
        NSDictionary *dic = [tutorialArray objectAtIndex:row];
        
        MissionListDetailController *missionListDetailController = [[[MissionListDetailController alloc] initWithNibName:@"MissionListDetailController" bundle: [NSBundle mainBundle]] autorelease];
        
        missionListDetailController.missionDic = dic;
        missionListDetailController.isTest = false;
        [self.navigationController pushViewController:missionListDetailController animated:YES];
    }
}


- (IBAction)segmentClick:(id)sender {
    [scrollview setContentOffset:CGPointMake(0, 0) animated:NO];
    
    if([sender selectedSegmentIndex] == 0){
        [self.btnTitle setTitle:NSLocalizedString(@"setting_title0", nil) forState:UIControlStateNormal];
        self.scrollview.alpha = 0;
        tableView.alpha = 1;
    }else{
        [self.btnTitle setTitle:NSLocalizedString(@"setting_title1", nil) forState:UIControlStateNormal];
        self.scrollview.alpha = 1;
        tableView.alpha = 0;
    }
}

- (IBAction)infoClick:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"setting_title2", nil)
                              message:NSLocalizedString(@"setting_title3", nil)
                              delegate:self 
                              cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                              otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    
    
    [alertView show];
    [alertView release];
    
    
    
}

- (IBAction)btnRightClick:(id)sender {
    [self setClickBtns:2];
}

- (IBAction)btnLeftClick:(id)sender {
    [self setClickBtns:1];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [self sendEmailTo:@"ejola21@gmail.com" withSubject:@"Play Spot" withBody:@""];
    }
}

- (void) sendEmailTo:(NSString *)toStr
         withSubject:(NSString *)subjectStr
            withBody:(NSString *) bodyStr
{
    NSString *emailString =
    [[NSString alloc] initWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
     [toStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
     [subjectStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
     [bodyStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailString]];
    
    [emailString release];
}
@end
