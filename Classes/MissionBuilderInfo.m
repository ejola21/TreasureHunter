//
//  MissionBuilderInfo.m
//  TreasureHunter
//
//  Created by ejola on 11. 3. 5..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MissionBuilderInfo.h"
#import "Mission.h"
#import "MissionItem.h"
#import "MissionBuilder.h"
#import "EditableDetailCell.h"
#import "TreasureHunterAppDelegate.h"
#import "MissionDao.h"
#import "ImageManager.h"
#import "JSON.h"

@implementation MissionBuilderInfo
@synthesize mTableView;
@synthesize mission,datePicker,cntPicker,pickerToolbar,activeView,activeField;


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
	[super viewDidLoad];
    
    badgeImg = [[ImageManager loadInfoBadgeImg:mission.mID] retain];
	
	if (mission.mPlace == nil) 
	{
		CLLocationCoordinate2D coordinate;
		
		if ([mission.mItems count])
		{
			MissionItem *missionItem = [mission.mItems objectAtIndex:0];
			coordinate.latitude = missionItem.latitude;
			coordinate.longitude = missionItem.longitude;
			//[self getPlaceMark:coordinate];
            [self getGooglePlaceMark:coordinate];
		}
		
	}
	self.navigationItem.title = NSLocalizedString(@"info_word_0", nil);
	
	UIBarButtonItem *eBtnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(editCancelClick)];
	UIBarButtonItem *eBtnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                             target:self
                                                                             action:@selector(editDoneClick)];
	
	[self.navigationItem setRightBarButtonItem:eBtnDone animated:YES];
	[self.navigationItem setLeftBarButtonItem:eBtnCancel animated:YES];
	
	[eBtnCancel release]; 
	[eBtnDone release];
	
	//self.tableView.editing = YES;
	self.tableView.allowsSelectionDuringEditing = YES;
	activeView = nil;
	activeField = nil;
	
	
	//picekr set
	pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	pickerToolbar.barStyle = UIBarStyleBlackOpaque;
	[pickerToolbar sizeToFit];
	
	NSMutableArray *barItems = [[[NSMutableArray alloc]init] autorelease];
	
	UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                     target:self action:nil];
	[barItems addObject:btnFlexibleSpace];
	[btnFlexibleSpace release];
	
	UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(pickerCancelClick)];
	[barItems addObject:btnCancel];
	[btnCancel release];
	
	UIBarButtonItem *btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                            target:self
                                                                            action:@selector(pickerDoneClick)];
	[barItems addObject:btnDone];
	[btnDone release];
	
	[pickerToolbar setItems:barItems animated:YES];
    
	
	//datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 320, 160)];
	datePicker = [[UIDatePicker alloc] init];
	datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	cntPicker = [[UIDatePicker alloc] init];
	cntPicker.datePickerMode = UIDatePickerModeCountDownTimer;
	textHeight = 35;
	
	//datePicker.datePickerMode = UIDatePickerModeTime;
	
}

/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */
/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */
#pragma mark -
#pragma mark reverseGeocoder
- (void)getGooglePlaceMark:(CLLocationCoordinate2D)coordinate
{
    
    //   http://maps.google.com/maps/api/geocode/json?latlng=40.714224,-73.961452&sensor=true&language=en
    //    NSString *fetchURL = [NSString stringWithFormat:@"http://maps.google.com/maps/geocode/json?latlng%@,%@&sensor=true", [NSString stringWithFormat:@"%f",coordinate.latitude], [NSString stringWithFormat:@"%f",coordinate.longitude]];
    
    NSString *lang = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
    NSString *fetchURL = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%@,%@&amp;output=json&amp;sensor=true&language=%@", [NSString stringWithFormat:@"%f",coordinate.latitude], [NSString stringWithFormat:@"%f",coordinate.longitude],lang];
    
    NSURL *url = [NSURL URLWithString:fetchURL];
    
    NSString *htmlData = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil ];
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *json = [parser objectWithString:htmlData error:nil];
    NSLog(@"address:%@",json);
    
    NSArray *placemark = [json objectForKey:@"Placemark"];
    NSLog(@"Placemark:%@",placemark);
    
    /*
    if ([[[[[[placemark objectAtIndex:0] objectForKey:@"AddressDetails"] objectForKey:@"Country"] objectForKey:@"AdministrativeArea"]objectForKey:@"Locality"] objectForKey:@"LocalityName"]!= NULL){
        
        //mission.mPlace = [[[[[[placemark objectAtIndex:0] objectForKey:@"AddressDetails"] objectForKey:@"Country"] objectForKey:@"AdministrativeArea"]objectForKey:@"Locality"] objectForKey:@"LocalityName"];
    }
    else {
        // mission.mPlace = [[placemark objectAtIndex:0] objectForKey:@"address"];
        NSString* str = [[placemark objectAtIndex:0] objectForKey:@"address"];
        NSArray* list = [str componentsSeparatedByString:@" "];
        mission.mPlace = [NSString stringWithFormat:@"%@ %@",[list objectAtIndex:[list count]-3],[list objectAtIndex:[list count]-2]] ;
        mission.mPlace = (NSMutableString *)str;
    }
    */
    
    mission.mPlace = [[placemark objectAtIndex:0] objectForKey:@"address"];
    
    [parser release];
    NSLog(@"mission.mPlace%@",mission.mPlace);
}
/*
 - (void)getPlaceMark : (CLLocationCoordinate2D) coordinate
 {
 //MKReverseGeocoder ios 5.0 deprecate
 //os 버젼별로  코딩 #if 
 reversGeocoder = [[[MKReverseGeocoder alloc] initWithCoordinate :coordinate] autorelease];  
 reversGeocoder.delegate = self;  
 [reversGeocoder start];  
 }
 
 // 뿌레스마쿠을 얻을 수있는 경우의 처리  
 - (void) reverseGeocoder : (MKReverseGeocoder *) geocoder didFindPlacemark : (MKPlacemark *) pm 
 { 
 mission.mPlace = (NSMutableString *)[NSString stringWithFormat:@"%@ %@",pm.locality,pm.thoroughfare];
 
 //NSLog([pm.addressDictionary description]);
 reversGeocoder.delegate = nil;
 [reversGeocoder autorelease];
 
 [self.tableView reloadData];
 }
 
 // 뿌레스마쿠 얻을 수없는 경우의 처리  
 - (void) reverseGeocoder : (MKReverseGeocoder *) geocoder didFailWithError : (NSError *) error
 {
 
 reversGeocoder.delegate = nil;
 [reversGeocoder autorelease];
 
 NSLog(@"Reverse geocoder error: %@", [error description]);	
 
 
 }
 */



#pragma mark -
#pragma mark util

- (BOOL)dataCheck
{
	BOOL ret = YES;
	
	NSString *atitle = nil;
	NSString *message = nil;
	
	if ([self stringIsEmpty:self.mission.mTitle])
	{
		atitle = NSLocalizedString(@"data_check_title_0", nil);
		message = NSLocalizedString(@"data_check_message_0", nil);
	}
	if ([self stringIsEmpty:self.mission.mDescription])
	{
		atitle = NSLocalizedString(@"data_check_title_1", nil);
		message = NSLocalizedString(@"data_check_message_1", nil);
	}
	if ([self stringIsEmpty:self.mission.mPlace])
	{
		atitle = NSLocalizedString(@"data_check_title_2", nil);
		message = NSLocalizedString(@"data_check_message_2", nil);
	}
   
    if ([self.mission.mQuiz length] > 0 && [self.mission.mAnswer length] < 1)
	{
		atitle = NSLocalizedString(@"info_check_title_3", nil);
		message = NSLocalizedString(@"info_check_message_3", nil);
	}
    if(badgeImg ==nil){
		atitle = NSLocalizedString(@"data_check_title_2_0", nil);
		message = NSLocalizedString(@"data_check_message_2_0", nil);
    }
	if (self.mission.mRunLimitTime == nil){
		atitle = NSLocalizedString(@"data_check_title_15", nil);
		message = NSLocalizedString(@"data_check_message_15", nil);
	}
    else {
        
        int limit = [[APPDEL toNSString:self.mission.mRunLimitTime :@"HHmmss"] intValue];
        if (limit <  500) {
            atitle = NSLocalizedString(@"data_check_title_16", nil);
            message = NSLocalizedString(@"data_check_message_16", nil);
        }
    }

	if(atitle != nil)
	{
		ret = NO;
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:atitle 
                                                             message:message
                                                            delegate:self 
                                                   cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                   otherButtonTitles:nil] autorelease];
		[alertView show];
	}
	
	return ret;
}

- (EditableDetailCell *)newDetailCellWithTag:(NSInteger)tag
{
	EditableDetailCell *cell =nil;
	if (tag == LONG_TEXT) {
		cell = [[EditableDetailCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                         reuseIdentifier:C_TEXT_VIEW];
		[[cell textView] setDelegate:self];
        [[cell textView] setTag:tag];
		cell.autoresizesSubviews = YES; 
        
	}
	else
	{
        cell = [[EditableDetailCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                         reuseIdentifier:nil];
		[[cell textField] setDelegate:self];
        [[cell textField] setFrame:CGRectMake(60, 10, 250, 40)];
        [[cell textField] setTag:tag];
        cell.autoresizesSubviews = YES;
	}
	
	return cell;
}


#pragma mark -
#pragma mark action

-(void)editCancelClick 
{
	//NSArray *allControllers = self.navigationController.viewControllers;
	//MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
	
	//missionBuilder.selectedAnno = self.loadItem;
	
	[self.navigationController popViewControllerAnimated:YES];
	
}

-(void)editDoneClick 
{
	//미입력된 TextField 저장
	if (activeView != nil) {
		if (activeView.tag == MISSION_TITLE) 
			mission.mTitle = (NSMutableString *)activeView.text;
		else if (activeView.tag == MISSION_DESCRIPTION) 
			mission.mDescription = (NSMutableString *)activeView.text;	
		else if (activeView.tag == MISSION_QUIZ) 
			mission.mQuiz = (NSMutableString *)activeView.text;	
	}
	if (activeField != nil) {
		if (activeField.tag == MISSION_PLACE) 
			mission.mPlace = (NSMutableString *)activeField.text;
		else if (activeField.tag == MISSION_ANSWER) 
			mission.mAnswer = (NSMutableString *)activeField.text;
	}
	mission.mDesigner = (NSMutableString *)[APPDEL gUserID];
	if ([self dataCheck] == NO) return;
    if(badgeImg!=nil){
        NSLog(@"%@",[UIImage imageNamed:@"mask1.png"]);
        [ImageManager saveImgWithID:mission.mID Image:[self maskImage:badgeImg maskt:[UIImage imageNamed:@"mask1.png"]]]; 
    }
	//우선 mission 저장 
	MissionDao *missionDao = [[[MissionDao alloc] init] autorelease];
	[missionDao save:self.mission];
	[self.navigationController popViewControllerAnimated:YES];
	
}

-(void)pickerDoneClick;
{
	[datePicker removeFromSuperview];
	[cntPicker removeFromSuperview];
	[pickerToolbar removeFromSuperview];
	
	if (datePicker.tag == 1)	
	{
		//NSString *tt = [APPDEL toNSString:[datePicker date]:@"yyyy-MM-dd HH:mm:00"];
		//mission.mStartTime = [APPDEL toNSDate:tt:@"yyyy-MM-dd HH:mm:ss"];
        mission.mStartTime = [datePicker date];
		
	}
	else if (cntPicker.tag == 2)	
	{   
        //NSString *tt = [APPDEL toGMTNSString:[cntPicker date]:@"yyyy-MM-dd HH:mm:00"];
        //mission.mRunLimitTime = [APPDEL toGMTNSDate:tt:@"yyyy-MM-dd HH:mm:ss"];
        mission.mRunLimitTime = [cntPicker date];
		NSLog(@"pickerDoneClick limitTime: %@",mission.mRunLimitTime);
	}
	
	[self.tableView reloadData];
	
}

-(void)pickerCancelClick
{
	[datePicker removeFromSuperview];
	[cntPicker removeFromSuperview];
	[pickerToolbar removeFromSuperview];
}


- (UISwitch *)switchCtl;
{
	if (switchCtl == nil) 
	{
		CGRect frame = CGRectMake(200.0, 8.0, 94.0, 27.0);
		switchCtl = [[UISwitch alloc] initWithFrame:frame];
		[switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
		
		// in case the parent view draws with a custom color or gradient, use a transparent color
		switchCtl.backgroundColor = [UIColor clearColor];
		
		//switchCtl.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
	}
	return switchCtl;
}
- (void)switchAction:(id)sender
{
	if ([sender isOn])
		mission.mVirtual = VIRTUAL_MODE;
	else
		mission.mVirtual = REAL_MODE;
}

#pragma mark -
#pragma mark Table view data source



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if (section == 2) 
        return NSLocalizedString(@"info_section_3", nil);
    else
        return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	NSInteger ret = 0;
	if (section == 0) ret = 1;
	else if (section == 1) ret = 5;
    else if (section == 2) ret = 2;
	return ret;	
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	NSInteger tag = INT_MIN;
	NSString *text = nil;
	NSString *placeholder =nil;
	NSString *title = nil;
	EditableDetailCell *keyCell = nil;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
		
		CGRect titleRect = CGRectMake(7,10,120,18);
		UILabel *celTitle = [[UILabel alloc] initWithFrame:titleRect];
		celTitle.textColor = [UIColor grayColor];
        [celTitle setBackgroundColor:[UIColor clearColor]];
		celTitle.font = [UIFont boldSystemFontOfSize:14];
		celTitle.tag = 77;        // 나중에 해당 레이블에게 값을 할당할 수 있도록 이 필드를 찾을 방법을 추가
		[cell.contentView addSubview:celTitle];
		[celTitle release];
		
		CGRect detailRect = CGRectMake(135,10,190,18);
		UILabel *celDetail = [[UILabel alloc] initWithFrame:detailRect];
        [celDetail setBackgroundColor:[UIColor clearColor]];
		//celTitle.textColor = [UIColor blueColor];
		//celTitle.font = [UIFont boldSystemFontOfSize:14];
		celDetail.tag = 78;        // 나중에 해당 레이블에게 값을 할당할 수 있도록 이 필드를 찾을 방법을 추가
		[cell.contentView addSubview:celDetail];
		[celDetail release];
    }
    
    if(indexPath.section == 0){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"MissionBuilderInfoCell" owner:self options:nil] objectAtIndex:0];
        
        UIButton *button = (UIButton *)[cell viewWithTag:300];
        if(badgeImg == nil){
            [button setBackgroundImage:[UIImage imageNamed:@"frame160_1.png"] forState:UIControlStateNormal];  
        }else{
            [button setBackgroundImage:[self maskImage:badgeImg maskt:[UIImage imageNamed:@"mask2.png"]] forState:UIControlStateNormal];
        }
        [button addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];  
        
        
       
        UILabel *label;
        label = (UILabel *)[cell viewWithTag:200];
        label.text = NSLocalizedString(@"info_word_3", nil);
        
        label = (UILabel *)[cell viewWithTag:201];
        label.text = NSLocalizedString(@"info_word_4", nil);
        
    }else if (indexPath.section == 1)
	{
		if (indexPath.row == 0) 
		{
			text = mission.mTitle;
			title = NSLocalizedString(@"info_word_title_0", nil);
			placeholder = NSLocalizedString(@"info_word_message_0", nil);
			tag = MISSION_TITLE;
			keyCell = [[self newDetailCellWithTag:LONG_TEXT] autorelease]; 
		}
		else if (indexPath.row == 1) 
		{ 
			text = mission.mDescription;
			title = NSLocalizedString(@"info_word_title_1", nil);
			placeholder = NSLocalizedString(@"info_word_message_1", nil);
			tag = MISSION_DESCRIPTION;
			keyCell = [[self newDetailCellWithTag:LONG_TEXT] autorelease]; 
		}
		else if (indexPath.row == 2) 
		{ 
			
			text = mission.mPlace;
			title = NSLocalizedString(@"info_word_title_2", nil);
			placeholder = NSLocalizedString(@"info_word_message_2", nil);
			tag = MISSION_PLACE;
			keyCell = [[self newDetailCellWithTag:SHORT_TEXT] autorelease]; 
          
		}
		else if (indexPath.row == 3) 
		{ 
			text = mission.mQuiz;
			title = NSLocalizedString(@"info_word_title_3", nil);
			placeholder = NSLocalizedString(@"info_word_message_3", nil);
			tag = MISSION_QUIZ;
			keyCell = [[self newDetailCellWithTag:LONG_TEXT] autorelease]; 
		}
		else if (indexPath.row == 4) 
		{ 
			
			text = mission.mAnswer;
			title = NSLocalizedString(@"info_word_title_4", nil);
			placeholder = NSLocalizedString(@"info_word_message_4", nil);
			tag = MISSION_ANSWER;
			keyCell = [[self newDetailCellWithTag:SHORT_TEXT] autorelease]; 
		}
		
		
	}else if (indexPath.section == 2) {
		
		UILabel *ltitle = (UILabel *)[cell.contentView viewWithTag:77]; 
		UILabel *ldetail = (UILabel *)[cell.contentView viewWithTag:78]; 
        [ltitle setBackgroundColor:[UIColor clearColor]];
        [ldetail setBackgroundColor:[UIColor clearColor]];
		if (indexPath.row == 0)
		{
			//UILabel *ltitle = (UILabel *)[cell.contentView viewWithTag:77];    // 해당 레이블 찾기
			ltitle.text = NSLocalizedString(@"info_word_1", nil);
            
            [cell.contentView addSubview:self.switchCtl];
            if (self.mission.mVirtual == VIRTUAL_MODE) 
                [self.switchCtl setOn:YES animated:YES];
            else 
                [self.switchCtl setOn:NO animated:YES];
            
			//ldetail.text = [APPDEL toNSString:mission.mStartTime :@"yyyy-MM-dd HH:mm:ss"];
			
		}
		else if (indexPath.row == 1) 
		{
			ltitle.text = NSLocalizedString(@"info_word_2", nil);
			ldetail.text = [APPDEL toNSString:mission.mRunLimitTime :@"HH:mm:ss"];
			NSLog(@"limitTime: %@",[APPDEL toNSString:mission.mRunLimitTime :@"yyyy-MM-dd HH:mm:ss"]);
			
		}
	}
	
	if (keyCell == nil)
	{
		return cell;
	}
	else
	{
		UITextField *textField = [keyCell textField];
		UITextView *textView = [keyCell textView];
        [textView setBackgroundColor:[UIColor clearColor]];
        [textField setBackgroundColor:[UIColor clearColor]];
		if (tag == MISSION_DESCRIPTION || tag == MISSION_TITLE || tag == MISSION_QUIZ)
		{
			if (![self stringIsEmpty:text]){
                [textView setText:text];
            }
			[textView setTag:tag];
			//keyCell.contentView set
			//[keyCell.contentView setFrame:CGRectMake(0, 0, keyCell.contentView.bounds.size.width - 10.0f, 65.0)];					
		}
		else
		{
			[textField setText:text];
            
			[textField setPlaceholder:placeholder];
			if(keyCell.textField.tag == NUM_TEXT)
				[textField setKeyboardType:UIKeyboardTypeNumberPad];
			[textField setTag:tag];
		}
		UILabel *label = [keyCell label];
        [label setBackgroundColor:[UIColor clearColor]];
		[label setText:title];
		
		return keyCell;
	}
	
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

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
 {   
 CGFloat heightForRow = 40.0;
 
 if ([indexPath row] == 1)
 {
 CGFloat tableViewHeight = [tableView bounds].size.height;
 heightForRow = tableViewHeight - ((1 - 1) * heightForRow);
 
 if (heightForRow < textHeight) 
 {
 heightForRow = textHeight;
 
 }
 else if ([indexPath row] == 2)
 {
 CGFloat tableViewHeight = [tableView bounds].size.height;
 heightForRow = tableViewHeight - ((2 - 1) * heightForRow);
 
 if (heightForRow < textHeight) 
 {
 heightForRow = textHeight;
 }
 }
 return heightForRow;
 }
 
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat ret = 40;
	
    if(indexPath.section ==0){
        ret = 80;
    }else if (indexPath.section == 1)
	{
		if (indexPath.row == 0 )
		{
			//cell 생성되기 전에 호출 못쓴다
			//EditableDetailCell *cell = (EditableDetailCell *)[self.tableView cellForRowAtIndexPath:indexPath];
			//UITextView *textView = (UITextView *)[cell viewWithTag:MISSION_TITLE];
			
			UIFont *font = [UIFont systemFontOfSize:20];
			CGSize withinSize  = CGSizeMake(tableView.frame.size.width, 1000);
			CGSize size = [mission.mTitle sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
			//int iH = size.height / 24;
			ret = (size.height > 24 )  ? size.height + 30 : 75;
		}
		else if (indexPath.row == 1)
		{
			
			UIFont *font = [UIFont systemFontOfSize:20];
			CGSize withinSize  = CGSizeMake(tableView.frame.size.width, 1000);
			CGSize size = [mission.mDescription sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
			//int iH = size.height / 24;
			ret = (size.height > 24 )  ? size.height + 30 : 75;
		}
		else if (indexPath.row == 3)
		{
			
			UIFont *font = [UIFont systemFontOfSize:20];
			CGSize withinSize  = CGSizeMake(tableView.frame.size.width, 1000);
			CGSize size = [mission.mDescription sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
			//int iH = size.height / 24;
			ret = (size.height > 24 )  ? size.height + 30 : 75;
		}
	}
	
	return ret;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	[APPDEL hideKeyboard];
	
	datePicker.tag = 0;
	cntPicker.tag = 0;
	
    if(indexPath.section ==0){
        [self onClickBadgeImg];
    }else if(indexPath.section == 2)
	{
		if (indexPath.row == 1)
		{
			cntPicker.tag = 2;
			[[APPDEL window] addSubview:pickerToolbar];
			[pickerToolbar setFrame:CGRectMake(0,226,320,44)];
			[[APPDEL window] addSubview:cntPicker];
			[cntPicker setFrame:CGRectMake(0,270,320,216)];
		}
	}
}


#pragma mark -
#pragma mark clickFunction textView

- (void)onClick:(id) sender
{
    [self onClickBadgeImg];
}

- (void)onClickBadgeImg{
    UIImagePickerController *picker;
    
    picker = [[UIImagePickerController alloc] init];
    [picker setAllowsEditing:true];
    
    [picker setDelegate:self];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
		didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
	[picker dismissModalViewControllerAnimated:YES];
}


- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    badgeImg = [[ImageManager ImageMerge:[ImageManager imageResizeImage: [info objectForKey:UIImagePickerControllerEditedImage]]]retain];
    
    
    [mTableView reloadData];
    
	[picker dismissModalViewControllerAnimated:YES];
    
}

- (UIImage*) maskImage:(UIImage *)image maskt:(UIImage *)maskImage{
    
    CGImageRef maskRef = maskImage.CGImage; 
    
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
    CGImageRelease(mask);
    UIImage *maskedImg = [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    return maskedImg;

    
}


#pragma mark -
#pragma mark textField textView

- (void)tableViewNeedsToUpdateHeight
{
	BOOL animationsEnabled = [UIView areAnimationsEnabled];
	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:animationsEnabled];
}
- (void)textViewDidChange:(UITextView *)textView
{
	
	
	if (textView.tag == MISSION_TITLE)
	{
		mission.mTitle = (NSMutableString *)textView.text;
	}	
	else if (textView.tag == MISSION_DESCRIPTION)
	{
		mission.mDescription = (NSMutableString *)textView.text;
	}
	else if (textView.tag == MISSION_QUIZ)
	{
		mission.mQuiz = (NSMutableString *)textView.text;
	}
	
	CGFloat newTextHeight = [textView contentSize].height;
	if (newTextHeight != textHeight)
	{
		textHeight = newTextHeight;
		[self tableViewNeedsToUpdateHeight];
	}
	
	
}

// done 클릭시 키보드 내리기
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text 
{ 
	if([text isEqualToString:@"\n"]) 
		[textView resignFirstResponder];
	
	
	/*
	 if (textView.tag == MISSION_TITLE)
	 {
	 mission.mTitle = (NSMutableString *)text;
	 }	
	 else if (textView.tag == MISSION_DESCRIPTION)
	 {
	 mission.mDescription = (NSMutableString *)text;
	 }
	 */
	return YES; 
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[textView resignFirstResponder];
	NSString *text = [textView text];
	
	if (textView.tag == MISSION_TITLE)
	{
		mission.mTitle = (NSMutableString *)text;
	}	
	else if (textView.tag == MISSION_DESCRIPTION)
	{
		mission.mDescription = (NSMutableString *)text;
	}
	else if (textView.tag == MISSION_QUIZ)
	{
		mission.mQuiz = (NSMutableString *)text;
	}
	activeView = nil;
	
}
- (void)textViewDidBeginEditing:(UITextView *)textView
{
	activeView = textView;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	activeField = textField;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
	/*
	 static NSNumberFormatter *_formatter;
	 
	 if (_formatter == nil)
	 {
	 _formatter = [[NSNumberFormatter alloc] init];
	 }
	 */
	[textField resignFirstResponder];
	NSString *text = [textField text];
	
	switch (textField.tag)
	{
		case MISSION_TITLE:		
		{
			mission.mTitle = (NSMutableString *)text; 
			break;
		}
		case MISSION_DESCRIPTION:		
		{
			mission.mDescription = (NSMutableString *)text; 
			break;
		}
		case MISSION_ANSWER:		
		{
			mission.mAnswer = (NSMutableString *)text; 
			break;
		}	
		case MISSION_PLACE:		
		{
			mission.mPlace = (NSMutableString *)text; 
			break;
		}
	}
	activeField = nil;
	
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField.returnKeyType == UIReturnKeyDone)
	{
		[textField resignFirstResponder];
	}
	/*
	 if ([textField returnKeyType] != UIReturnKeyDone)
	 {
	 //  If this is not the last field (in which case the keyboard's
	 //  return key label will currently be 'Next' rather than 'Done'), 
	 //  just move the insertion point to the next field.
	 //
	 //  (See the implementation of -textFieldShouldBeginEditing: above.)
	 //
	 NSInteger nextTag = [textField tag] + 1;
	 UIView *nextTextField = [[self tableView] viewWithTag:nextTag];
	 
	 [nextTextField becomeFirstResponder];
	 }
	 
	 else if ([self isModal])
	 {
	 //  We're in a modal navigation controller, which means the user is
	 //  adding a new book rather than editing an existing one.
	 //
	 [self save];
	 }
	 else
	 {
	 [[self navigationController] popViewControllerAnimated:YES];
	 }
	 */
	return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    self.mission = nil;
	self.pickerToolbar =nil;
	self.datePicker = nil;
	self.cntPicker = nil;
	self.activeField = nil;
	self.activeView= nil;
    [self setMTableView:nil];
    [switchCtl release]; switchCtl= nil;
	// Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	// For example: self.myOutlet = nil;
}


- (void)dealloc {
	[mission release];
	[pickerToolbar release];
	[datePicker release];
	[cntPicker release];
	[activeField release];
	[activeView release];
    [switchCtl release];  
    [mTableView release];
	[super dealloc];
}


@end

