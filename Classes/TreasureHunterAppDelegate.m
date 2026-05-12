//
//  TreasureHunterAppDelegate.m
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TreasureHunterAppDelegate.h"
#import "Mission.h"
#import "MissionPlay.h"
#import "MissionInPlay.h"
#import "MissionItemInPlay.h"
#import "MissionInPlayDao.h"
#import "MissionItemInPlayDao.h"
#import "MissionItem.h"
#import "MissionItemDao.h"
#import "MissionBuilderList.h"
#import "MyInfo.h"
#import "Login.h"
#import "ImageManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioPlayer.h>


@implementation TreasureHunterAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize locationManager,startPoint;
@synthesize itemType,showType, effectiveRange,itemGame,itemAlphabet,itemNumber,rangeAR,blackCnt,blackTime,mandatory; //effectiveCount,;
@synthesize itemTypeKeys,itemTypeObjects,showTypeKeys,showTypeObjects;
@synthesize gUserID,itemSeq,buildingMissions,db,playMission;
@synthesize itemTypeFiles;
@synthesize playedImg, designedImg, designedArray, playedArray,backColor, cellColor;
@synthesize designCount, playedCount,playingDic,solutionCount, timeAddCount;
@synthesize soundIDDic;
@synthesize guestUserID;
/*
 +(BOOL) isGameCenterAvailable
 {
 // Check for presence of GKLocalPlayer class.
 BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
 
 // The device must be running iOS 4.1 or later.
 NSString *reqSysVer = @"4.1";
 NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
 BOOL osVersionSupported = ([currSysVer compare:reqSysVer
 options:NSNumericSearch] != NSOrderedAscending);
 
 return (localPlayerClassAvailable && osVersionSupported);
 }
 */
//itemGameObjects,itemGameKeys, itemGame, 
#pragma mark -
#pragma mark Application util

-(NSString *)toGMTNSString:(NSDate *)inDate :(NSString *)dFormat
{
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
	[dateFormat setDateFormat:dFormat];
	NSString *dateString = [dateFormat stringFromDate:inDate];
	return dateString;
}
-(NSDate *)toNSDate:(NSString *)inString : (NSString *)dFormat
{
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat:dFormat];
    
    [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
	NSDate *date = [dateFormat dateFromString:inString];  
    return date;
}

-(NSString *)toNSString:(NSDate *)inDate :(NSString *)dFormat
{
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat:dFormat];
    [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
	NSString *dateString = [dateFormat stringFromDate:inDate];
	return dateString;
}
-(NSDate *)toGMTNSDate:(NSString *)inString : (NSString *)dFormat
{
	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormat setDateFormat:dFormat];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
	NSDate *date = [dateFormat dateFromString:inString];  
    return date;
}

-(NSString *)sec2timeFormat:(int) seconds
{
    return [NSString stringWithFormat:@"%02u:%02u:%02u", seconds / 3600, (seconds / 60) % 60, seconds % 60];
}

-(int)timeFormat2sec:(NSString *) timeFormat
{
    NSArray *components = [timeFormat componentsSeparatedByString:@":"];
    
    NSInteger hours   = [[components objectAtIndex:0] integerValue];
    NSInteger minutes = [[components objectAtIndex:1] integerValue];
    NSInteger seconds = [[components objectAtIndex:2] integerValue];
    
    return (hours * 60 * 60) + (minutes * 60) + seconds;
}

//키보드를 사라지게 하기 위해 사용하는 재귀함수 
- (void)_hideKeyboardRecursion:(UIView*)view 
{
	if ([view conformsToProtocol:@protocol(UITextInputTraits)]) 
	{
		[view resignFirstResponder];
	}	
	if ([view.subviews count]>0) 
	{
		for (int i = 0; i < [view.subviews count]; i++) 
		{
			[self _hideKeyboardRecursion:[view.subviews objectAtIndex:i]];
		}
	}
}

//키보드 감추기
- (void)hideKeyboard 
{
	UIWindow *tempWindow;
	
	for (int c=0; c < [[[UIApplication sharedApplication] windows] count]; c++) 
	{
		tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:c];
		for (int i = 0; i < [tempWindow.subviews count]; i++) 
		{
			[self _hideKeyboardRecursion:[tempWindow.subviews objectAtIndex:i]];
		}
	}
}

#pragma mark -
#pragma mark SoundManager

/*
 배경음 연주
 - (void)playBackground:(int)kind{
 if(self.opSound == 1){
 if(kind == 0){
 [player0 play];
 [player1 pause];
 [player2 pause];
 } else if(kind == 1){
 [player0 pause];
 [player1 play];
 [player2 pause];
 } else if(kind == 2){
 [player0 pause];
 [player1 pause];
 [player2 play];
 } else {
 [player0 pause];
 [player1 pause];
 [player2 pause];
 }
 }else{
 [player0 pause];
 [player1 pause];
 [player2 pause];
 }
 }
 
 배경음 MP3설정
 - (void) initPlaySound{
 
 NSString *soundFilePath0 = [[NSBundle mainBundle] pathForResource:@"main_bg" ofType:@"mp3"];
 NSURL *soundFileURL0 = [NSURL fileURLWithPath:soundFilePath0];
 player0 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL0 error:nil];
 player0.numberOfLoops = -1; //infinite
 
 NSString *soundFilePath1 = [[NSBundle mainBundle] pathForResource:@"game_bg1" ofType:@"mp3"];
 NSURL *soundFileURL1 = [NSURL fileURLWithPath:soundFilePath1];
 player1 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL1 error:nil];
 player1.numberOfLoops = -1; //infinite
 
 NSString *soundFilePath2 = [[NSBundle mainBundle] pathForResource:@"game_bg0" ofType:@"mp3"];
 NSURL *soundFileURL2 = [NSURL fileURLWithPath:soundFilePath2];
 player2 = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL2 error:nil];
 player2.numberOfLoops = -1; //infinite
 
 NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc] initWithCapacity:20];
 self.soundIDDic = tmpDic;
 [tmpDic release];
 }
 
 */

- (void) initPlaySound{
    
    NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc] initWithCapacity:20];
    self.soundIDDic = tmpDic;
    [tmpDic release];
}


//[APPDEL playSystemSound:@"main_select"  fileType:@"mp3"]; 


- (void) playSystemSound:(NSString*)fileName fileType:(NSString*)type{
    @try {
        NSNumber *num = (NSNumber*) [self.soundIDDic objectForKey:fileName];
        SystemSoundID soundID;
        
        if(num == nil) {
            NSBundle *mainBundle = [NSBundle mainBundle];
            NSString *path = [mainBundle pathForResource:fileName ofType:type inDirectory:@"sounds"];
            
            AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &soundID);
            
            
            num = [[NSNumber alloc] initWithUnsignedLong:soundID];
            [self.soundIDDic setObject:num forKey:fileName];
        }else {
            soundID = [num unsignedLongValue];
        }

        AudioServicesPlaySystemSound(soundID);

    }@catch(NSException* e) {
        
    }
}

- (void) deallocPlaySound{
    if(self.soundIDDic != nil && [self.soundIDDic count] > 0) {
        NSArray *IDs = [self.soundIDDic allValues];
        if(IDs != nil) {
            for(NSInteger i = 0; i < [IDs count]; i++) {
                NSNumber *num = (NSNumber*) [IDs objectAtIndex:i];
                if(num == nil)
                    continue;
                
                SystemSoundID soundID = [num unsignedLongValue];
                AudioServicesDisposeSystemSoundID(soundID);
            }
        }
    }
    [soundIDDic release];
    
}


#pragma mark -
#pragma mark locationManager



- (void)locationManagerInit: (id)sender
{
	
	//self.theMapView.showsUserLocation = YES;
    
	locationManager.delegate = sender;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest; //10m
	startPoint = nil;
	[locationManager startUpdatingLocation];
	
}
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {  
    if(newLocation.horizontalAccuracy < 0.0) return;
    
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        NSLog(@"AppDel latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
        self.startPoint = newLocation;
    }
	
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    locationManager = [[CLLocationManager alloc] init];
    [self locationManagerInit:self];
	if (![self initDatabase]){
		NSLog(@"Failed to init Database.");
	} 
    
    
	itemTypeKeys = [[NSArray alloc] initWithObjects:I_START,I_END,I_SIMPLE,I_QUIZ,I_RANDOM,I_TIMEOUT_S,I_TIMEOUT_E,I_MINE,I_BLACK, I_MINE_NOBOMB,I_SOLUTION,I_RADAR_AR,I_RADAR_MAP,I_RADAR_MINE,I_COUPON,I_STORE,nil];
    
	itemTypeObjects = [[NSArray alloc] initWithObjects: @"Start",@"End",@"Hint",@"Quiz", @"Gambling",@"Run Start",@"Run End", @"Mine", @"Dark", @"Defense",@"Solution",@"Stealth Radar",@"Map Radar",@"Mine Radar",@"쿠폰",@"Store",nil];
	itemTypeFiles = [[NSArray alloc] initWithObjects: @"start",@"end",@"simple",@"quiz",@"random_box",@"time_start",@"time_end", @"mine", @"black", @"mine_nobomb",@"genius",@"radar_ar",@"radar_map",@"radar_mine",@"coupon",@"store",nil];
	
	showTypeKeys = [[NSArray alloc] initWithObjects:SHOW_ALL,SHOW_AR,SHOW_MAP,nil];
	showTypeObjects = [[NSArray alloc] initWithObjects:@"Normal",@"Hidden",@"Stealth",nil];
	
    //effectiveTime = [[NSArray alloc] initWithObjects: @"0",@"10", @"20", @"30", @"40",@"50",@"60",nil]; 
	//itemGame = [[NSArray alloc] initWithObjects:@"없음",@"난이도 하",@"난이도 중", @"난이도 상",nil];
    
    itemGame = [[NSArray alloc] initWithObjects: NSLocalizedString(@"appDel_game0", nil),NSLocalizedString(@"appDel_game1", nil),NSLocalizedString(@"appDel_game2", nil),NSLocalizedString(@"appDel_game3", nil),nil];
    mandatory = [[NSArray alloc] initWithObjects:NSLocalizedString(@"appDel_option", nil),NSLocalizedString(@"appDel_mandatory", nil),nil]; 
	effectiveRange = [[NSArray alloc] initWithObjects: @"2", @"3", @"4", @"5",@"6",@"7",@"8",@"9",@"10", @"20", @"30", @"40",@"50",@"60",nil];	
	rangeAR = [[NSArray alloc] initWithObjects:@"30", @"40", @"50", @"60", @"70", @"80", @"90", @"100",nil]; 
	blackCnt = [[NSArray alloc] initWithObjects:@"1", @"2", @"3", @"4", @"5",@"6",@"7",@"8",@"9",@"10",nil];
    //현재 구현 안됨
	blackTime = [[NSArray alloc] initWithObjects:@"5분", @"6분", @"7분", @"8분", @"9분",@"10분",nil];

    
    
    playingDic = [[NSMutableDictionary alloc] init];
    playedImg = [[NSMutableDictionary alloc] init];
    designedImg = [[NSMutableDictionary alloc] init];
    playedArray = [[NSMutableArray alloc] init];
    designedArray = [[NSMutableArray alloc] init];
    self.playedCount = -1;
    self.designCount = -1;
    
	[tabBarController setDelegate:self];
    
    self.solutionCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"solution"];
    self.timeAddCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"timeAdd"];
    
    
    guestUserID = [[NSUserDefaults standardUserDefaults] stringForKey: @"guestUserID"];
    
    if(guestUserID == nil){
        //GuestID 생성    
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
        NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"MMddhhmmssSSS"];
        
        self.guestUserID = [NSString stringWithFormat:@"Guest@%@",[dateFormatter stringFromDate:date]];

    }
    
    
    NSString *tempUser = [[NSUserDefaults standardUserDefaults] stringForKey: @"gUserID"];
    
    if([self stringIsEmpty:tempUser]){
        
        
        self.gUserID = self.guestUserID;
    }else{
        self.gUserID = tempUser;
    }
    
    NSLog(@"asdfasdf%@" ,guestUserID);
        NSLog(@"asdfasdf%@" ,gUserID);
    
    if ([self.gUserID isEqualToString:self.guestUserID]) {
        self.tabBarController.selectedIndex = 4;
    }
    self.backColor = RGBA(0, 144, 152, 1);
    self.cellColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    
    
	buildingMissions = [[NSMutableArray alloc] init];
    [tabBarController.tabBar setTintColor:[UIColor blackColor]];
    
    playMission = [[Mission alloc] init];
	[playMission getDBBuildMissions];
    [self initPlaySound];
	
	[window addSubview:tabBarController.view];
	[window makeKeyAndVisible];
	
	return YES;
}

- (BOOL) stringIsEmpty:(NSString *) aString {
    
    if ((NSNull *) aString == [NSNull null]) {
        return YES;
    }
    
    if (aString == nil) {
        return YES;
    } else if ([aString length] == 0) {
        return YES;
    } else {
        aString = [aString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aString length] == 0) {
            return YES;
        }
    }
    
    return NO;  
}



- (void) checkNAddImg:(NSString*)missionID{
    @try {
        UIImage *tempImg = (UIImage*) [self.playedImg objectForKey:missionID];
        
        if(tempImg == nil) {
            [self.playedImg setObject:[ImageManager loadBadgeImg:missionID] forKey:missionID];
        }
    }@catch(NSException* e) {
        
    }
}


- (void) checkNAddDesignImg:(NSString*)missionID{
    @try {
        UIImage *tempImg = (UIImage*) [self.designedImg objectForKey:missionID];
        
        if(tempImg == nil) {
            [self.designedImg setObject:[ImageManager loadBadgeImg:missionID] forKey:missionID];
        }
    }@catch(NSException* e) {
        
    }
}

- (void)regGUserID:(NSString *)_gUserID{
    self.gUserID = _gUserID;
    [[NSUserDefaults standardUserDefaults] setValue:self.gUserID forKey:@"gUserID"];
}

- (void)setGuestUserID:(NSString *)_guestUserID{
    guestUserID = _guestUserID;
    [[NSUserDefaults standardUserDefaults] setValue:self.guestUserID forKey:@"guestUserID"];
}

- (void)setSolutionCount:(int)_solutionCount{
    solutionCount = _solutionCount;
    if(solutionCount<0){
        solutionCount = 0;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:self.solutionCount forKey:@"solution"];
}

- (void)setTimeAddCount:(int)_timeAddCount{
    timeAddCount = _timeAddCount;
    if(timeAddCount < 0){
        timeAddCount = 0;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:self.timeAddCount forKey:@"timeAdd"];
}



- (NSDictionary *)itemType{
	if (itemType != nil){
		return itemType;
	}
	itemType = [[NSDictionary alloc] initWithObjects:itemTypeObjects forKeys:itemTypeKeys];
	return itemType;
}
- (NSDictionary *)showType{
	if (showType != nil){
		return showType;
	}
	showType = [[NSDictionary alloc] initWithObjects:showTypeObjects forKeys:showTypeKeys];
	return showType;
}


- (NSString *)itemMapFile:(NSMutableString	*)itemType1
{
	if([itemTypeKeys indexOfObject:itemType1] == NSNotFound)
	{
		return @"i_simple.png";
	}
	
	NSString *fileName = [NSString stringWithFormat:@"i_%@.png",[itemTypeFiles objectAtIndex:[itemTypeKeys indexOfObject:itemType1]]];    
	NSLog(@"itemType1:%@,fileName:%@",itemType1,fileName);
	return fileName;
}

- (NSString *)itemMandatoryMapFile:(NSMutableString	*)itemType1
{
	if([itemTypeKeys indexOfObject:itemType1] == NSNotFound)
	{
		return @"in_simple.png";
	}
	
	NSString *fileName = [NSString stringWithFormat:@"in_%@.png",[itemTypeFiles objectAtIndex:[itemTypeKeys indexOfObject:itemType1]]];    
	NSLog(@"itemType1:%@,fileName:%@",itemType1,fileName);
	return fileName;
}


- (NSString *)itemAcquiredMapFile:(NSMutableString	*)itemType1
{
	if([itemTypeKeys indexOfObject:itemType1] == NSNotFound)
	{
		return @"i_simple.png";
	}
	
	NSString *fileName = [NSString stringWithFormat:@"i_%@.png",[itemTypeFiles objectAtIndex:[itemTypeKeys indexOfObject:itemType1]]];    
	return fileName;
}

- (NSString *)itemARFile:(NSMutableString	*)itemType1
{
	if([itemTypeKeys indexOfObject:itemType1] == NSNotFound)
	{
		return @"ar_simple.png";
	}
	
	NSString *fileName = [NSString stringWithFormat:@"ar_%@.png",[itemTypeFiles objectAtIndex:[itemTypeKeys indexOfObject:itemType1]]];    
	return fileName;
}

- (NSString *)itemMandatoryARFile:(NSMutableString	*)itemType1
{
	if([itemTypeKeys indexOfObject:itemType1] == NSNotFound)
	{
		return @"arn_simple.png";
	}
	
	NSString *fileName = [NSString stringWithFormat:@"arn_%@.png",[itemTypeFiles objectAtIndex:[itemTypeKeys indexOfObject:itemType1]]];    
	return fileName;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
    /*
     [[NSNotificationCenter defaultCenter] postNotificationName: @"willResignActive" 
     object: nil 
     userInfo: nil];
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
	 */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	/*
	 Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
	 */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
    /*
     [[NSNotificationCenter defaultCenter] postNotificationName: @"didBecomeActive" 
     object: nil 
     userInfo: nil];
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
	/*
	 Called when the application is about to terminate.
	 See also applicationDidEnterBackground:.
	 */
}

#pragma mark -
#pragma mark Application db
- (BOOL)initDatabase{
	BOOL success;
	NSError *error;  
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"treasure.sqlite"];
	
	success = [fm fileExistsAtPath:writableDBPath];
	if(!success){
		NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"treasure.sqlite"];
		success = [fm copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
		if(!success){
			NSLog(@"db init error:%@",[error localizedDescription]);
		}
	}
	if(success){
		db = [[FMDatabase databaseWithPath:writableDBPath] retain];
		if ([db open]) {
			[db setShouldCacheStatements:YES];
		}else{
			NSLog(@"Failed to open database.");
			success = NO;
		}
	}      
	return success;  
}

- (void) closeDatabase{
	[db close];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate methods


// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController.tabBarItem.title isEqualToString:@"Design"] || [viewController.tabBarItem.title isEqualToString:@"My Info"] 
        || [viewController.tabBarItem.title isEqualToString:@"Badge"]) {
        
        if ([[APPDEL gUserID] isEqualToString:self.guestUserID]) {
            Login *user = [[[Login alloc] init] autorelease];
            [viewController presentModalViewController:user animated:YES];
        }
        
        if ([[APPDEL gUserID] isEqualToString:self.guestUserID]) {
            self.tabBarController.selectedIndex = 0;
            return;
        }
    }
}


/*
 // Optional UITabBarControllerDelegate method.
 - (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
 }
 */


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	/*
	 Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
	 */
}


- (void)dealloc {
    [self deallocPlaySound];
    
	[tabBarController release];
	[window release];
	[itemType release];
	[showType release];
	[penalty release];
	[reward release];
	[locationManager release];
    [playedImg release];
    [playedArray release];
    [designedArray release];
    [designedImg release];
    
    self.playingDic = nil;
	self.db = nil;
	self.buildingMissions = nil;
	self.effectiveRange = nil;
    
	self.itemNumber =nil;
	self.itemAlphabet = nil;
	self.gUserID = nil;
	self.mandatory = nil;
	
	self.itemTypeKeys = nil;
	self.itemTypeObjects = nil;
	self.showTypeKeys = nil;
	self.showTypeObjects = nil;
	self.itemTypeFiles = nil;
	self.playMission = nil;
	
	[super dealloc];
}

@end

