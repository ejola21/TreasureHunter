//
//  MissionBuilderDetail.m
//  TreasureHunter
//
//  Created by noh jh on 11. 1. 30..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MissionBuilderDetail.h"
#import "EditableDetailCell.h"
#import "TreasureHunterAppDelegate.h"
#import "AnnoItem.h"
#import "MissionBuilder.h"
#import "Mission.h"
#import "MissionItemDao.h"
#import "ItemQuizDao.h"
#import "MissionDao.h"
#import "LabeledPickerView.h"

#define kViewTag				1		// for tagging our embedded controls for removal at cell recycle time

@implementation MissionBuilderDetail
@synthesize annoItem,dataPicker,dataPickerToolbar,tableSection,loadItem,min,sec;//,datePicker,longText,shortText,numText;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
 
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 
 }
 */


#pragma mark -


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	loadItem = [self.annoItem copy];
	
	self.navigationItem.title = [[APPDEL itemType] valueForKey:annoItem.missionItem.itemType];
	
    /*
	UIBarButtonItem *eBtnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(editCancelClick)];
     */
	UIBarButtonItem *eBtnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                             target:self
                                                                             action:@selector(editSaveClick)];
	
	[self.navigationItem setLeftBarButtonItem:eBtnDone animated:YES];
	//[self.navigationItem setLeftBarButtonItem:eBtnCancel animated:YES];
	
	//[eBtnCancel release]; 
	[eBtnDone release];
	
	tableList = [[NSMutableArray alloc] init];
	[self makeTableSectionInfo];
	
	self.tableView.editing = YES;
	self.tableView.allowsSelectionDuringEditing = YES;
	activeView = nil;
	activeField = nil;
	
	//picekr set
	self.dataPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	self.dataPickerToolbar.barStyle = UIBarStyleBlackOpaque;
	[self.dataPickerToolbar sizeToFit];
	
	NSMutableArray *barItems = [[[NSMutableArray alloc]init] autorelease];
	
	UIBarButtonItem *btnFlexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                     target:self action:nil];
	[barItems addObject:btnFlexibleSpace];
	[btnFlexibleSpace release];
	
	UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self
                                                                              action:@selector(dataPickerCancelClick)];
	[barItems addObject:btnCancel];
	[btnCancel release];
	
	UIBarButtonItem *btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                            target:self
                                                                            action:@selector(dataPickerDoneClick)];
	[barItems addObject:btnDone];
	[btnDone release];
	
	[dataPickerToolbar setItems:barItems animated:YES];
	
	self.dataPicker = [[LabeledPickerView alloc] initWithFrame:CGRectZero];
	self.dataPicker.delegate = self; 
	self.dataPicker.dataSource = self;
	self.dataPicker.showsSelectionIndicator = YES;
    
	
	CGRect pickerFrame;
	
	pickerFrame.size.width = 320*1.0f;
	pickerFrame.size.height =  162*1.0f;
	pickerFrame.origin.x = 0;
	pickerFrame.origin.y = 44;
	
	dataPicker.frame = pickerFrame;  
	
	
	min = [[NSMutableArray alloc] init];
	for (int i = 0 ; i < 100 ; i++)
	{
		NSString *mm = [NSString stringWithFormat:@"%d",i];
		[self.min addObject:mm];
	}
	
	sec = [[NSMutableArray alloc] init];
	for (int i = 0 ; i < 60 ; i++)
	{
		NSString *ss = [NSString stringWithFormat:@"%d",i];
		[self.sec addObject:ss];
	}
	
	//LabeledPickerView *editorview = [[LabeledPickerView alloc] init];
	
	
	//삭제 버튼 
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
	
    
	UIButton *delButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	delButton.frame = CGRectMake(10, 10, 300, 44);
	NSString *title = [NSString stringWithFormat:@"%@ Delete",[[APPDEL itemType] valueForKey:self.annoItem.missionItem.itemType]];
	[delButton setTitle:title forState:UIControlStateNormal];
	[delButton addTarget:self action:@selector(delButtonClick:) forControlEvents:UIControlEventTouchUpInside];
	
    [delButton setBackgroundImage:[[UIImage imageNamed:@"delete_button.png"]
                                           stretchableImageWithLeftCapWidth:8.0f
                                           topCapHeight:0.0f]
                                 forState:UIControlStateNormal];
    
    [delButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    delButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    delButton.titleLabel.shadowColor = [UIColor lightGrayColor];
    delButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    
    [footerView addSubview:delButton];
   
    self.tableView.tableFooterView = footerView;
	
}





- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
    
    [switchCtl release]; switchCtl= nil;
	self.min = nil;
	self.sec = nil;
	self.annoItem = nil;
	self.loadItem = nil;
	self.dataPicker =nil;
	self.dataPickerToolbar =nil;
    //	self.datePicker = nil;
	self.tableSection =nil;
	[tableList release];
	[relatedItems release];
	relatedItems = nil;
}


- (void)dealloc {
	//[_missionItem release];
	[switchCtl release];
	[min release];
	[sec release];
	[annoItem release];
	[loadItem release];
	[dataPicker release];
	[dataPickerToolbar release];
    //	self.datePicker = nil;
	[tableSection release];
	[tableList release];
	[relatedItems release];
	relatedItems = nil;
	
	[super dealloc];
}

//  Override this method to automatically place the insertion point in the
//  first field.
//
/*
 - (void)viewWillAppear:(BOOL)animated
 {
 
 [super viewWillAppear:animated];
 
 [[NSNotificationCenter defaultCenter] 
 addObserver:self 
 selector:@selector(keyboardDidShow:)
 name:UIKeyboardDidShowNotification
 object:nil];
 
 [[NSNotificationCenter defaultCenter] 
 addObserver:self 
 selector:@selector(keyboardDidHide:)
 name:UIKeyboardDidHideNotification
 object:nil];
 
 keyboardVisible = NO;
 }
 */
//  Force textfields to resign firstResponder so that our implementation of
//  -textFieldDidEndEditing: gets called. That will ensure that the current
//  UI values are flushed to our model object before we return to the list view.
//
/*
 - (void)viewWillDisappear:(BOOL)animated
 {
 //NSLog(@"MissionBuilderDetail viewWillDisAppear");
 [super viewWillDisappear:animated];
 //[[NSNotificationCenter defaultCenter] removeObserver:self];
 
 }
 */
#pragma mark -
#pragma mark util

- (void)activeViewSave;
{
	if (activeView != nil)
	{	
		
		NSString *text = [activeView text];
		
		int _section = activeView.tag / 10;
		int _row = activeView.tag % 10;
		
		int k = [[[[[tableList objectAtIndex:_section] objectForKey:@"data"] objectAtIndex:_row] objectForKey:@"keyin"] intValue];
		
		int ix =  k / 10;
		int keyin =  k % 10;
		
		if (keyin == KEYIN_INFO)
		{
			self.annoItem.missionItem.info = (NSMutableString *)text;
		}
		else if (keyin == KEYIN_QUIZ)
		{
			ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:ix];
			itemQuiz.quiz = (NSMutableString *)text;
		}
	}
	
	/*	
     if ((activeView.tag / 10) % 10 == ITEM_QUIZ)
     {
     ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:(activeView.tag/100)];
     
     if (activeView.tag % 10 == QUIZ)
     itemQuiz.quiz = (NSMutableString *)text;
     }
     else 
     {
     self.annoItem.missionItem.info = (NSMutableString *)text;
     }
     
     }
	 */
}
- (void)activeFieldSave;
{
	if (activeField != nil)
	{
		NSString *text = [activeField text];
		
		int _section = activeField.tag / 10;
		int _row = activeField.tag % 10;
		
		int k = [[[[[tableList objectAtIndex:_section] objectForKey:@"data"] objectAtIndex:_row] objectForKey:@"keyin"] intValue];
		
		int ix =  k / 10;
		int keyin =  k % 10;
		
		if (keyin == KEYIN_ANSWER)
		{
			ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:ix];
			itemQuiz.answer = (NSMutableString *)text;
		}
	}
	/*		 
     switch ((activeField.tag / 10) % 10 )
     {
     case ITEM_END:
     {
     self.annoItem.missionItem.info = (NSMutableString *)text;
     break;
     }
     case ITEM_QUIZ:		
     {
     ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:(activeField.tag/100)];
     
     switch (activeField.tag % 10)
     {
     //case QUIZ: itemQuiz.quiz = (NSMutableString *)text;		break;
     case ANSWER: itemQuiz.answer = (NSMutableString *)text;		break;
     case Q_PROBABILITY: itemQuiz.probability = [text intValue];		break;
     }
     
     break;
     }
     case ITEM_REWARD:
     {
     ItemRnP *itemReward = [self.annoItem.missionItem.itemRewards objectAtIndex:(activeField.tag/100)];
     
     switch (activeField.tag % 10)
     {
     case R_INCREASE: itemReward.increase = [text intValue];		break;
     case R_PROBABILITY: itemReward.probability = [text intValue];		break;
     }
     
     break;
     }
     case ITEM_PENALTY:
     {
     ItemRnP *itemPenalty = [self.annoItem.missionItem.itemPenalties objectAtIndex:(activeField.tag/100)];
     
     switch (activeField.tag % 10)
     {
     case R_INCREASE: itemPenalty.increase = [text intValue];		break;
     case R_PROBABILITY: itemPenalty.probability = [text intValue];		break;
     }
     
     break;
     }
     }
     }	
	 */
}


- (UISwitch *)switchCtl;
{
	if (switchCtl == nil) 
	{
		CGRect frame = CGRectMake(150.0, 8.0, 94.0, 27.0);
		switchCtl = [[UISwitch alloc] initWithFrame:frame];
		[switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
		
		// in case the parent view draws with a custom color or gradient, use a transparent color
		switchCtl.backgroundColor = [UIColor clearColor];
		
		switchCtl.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
	}
	return switchCtl;
}

- (BOOL)dataCheck
{
	BOOL ret = YES;
	
	NSString *atitle = nil;
	NSString *message = nil;
	
	if ([self.annoItem.missionItem.itemType isEqualToString:I_QUIZ])
	{
		int cnt = [self.annoItem.missionItem.itemQuizzes count];
		
		if (cnt == 0) {
			
			atitle = NSLocalizedString(@"data_title", nil);
			message = NSLocalizedString(@"data_message", nil);
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

#pragma mark -
#pragma mark Action 

- (void)makeTableSectionInfo
{
	//table data init
	//공통 95
	//quiz 11,12
	//reward 21,20,22
	//penalty 31,30,32
	
	// relatedItems setting....	///////////////	///////////////	///////////////	///////////////	///////////////
	if ([self.annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_E])
	{
		NSArray *allControllers = self.navigationController.viewControllers;
		MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
        
		NSMutableArray *timeOutItems = [[[NSMutableArray alloc] init] autorelease]; 
		
		for (int i = 0; i < [missionBuilder.mission.mItems count]; i++)
		{
			MissionItem *mItem = [missionBuilder.mission.mItems objectAtIndex:i];
			if ([mItem.itemType isEqualToString:I_TIMEOUT_S])
				[timeOutItems addObject:mItem];
			// 추가는 여기에 ...
		}
		
		[relatedItems release];
		relatedItems = [[NSDictionary alloc] initWithDictionary:
                        [NSDictionary dictionaryWithObjectsAndKeys:
                         timeOutItems,I_TIMEOUT_S,nil]];
	}
	///////////////	///////////////	///////////////	///////////////	///////////////	///////////////	///////////////
	
	//만들때 null 이만들어질만한건 제일뒤로 빼라 
	[tableList removeAllObjects];
	
	
	NSString *ctrl = @"";
	
	if ([self.annoItem.missionItem.itemType characterAtIndex:0] =='4')
		self.annoItem.missionItem.mandatory = MANDATORY_Y;
	else if ([self.annoItem.missionItem.itemType isEqualToString:I_STORE] || [self.annoItem.missionItem.itemType isEqualToString:I_MINE] ||
             [self.annoItem.missionItem.itemType isEqualToString:I_BLACK] ||
             [self.annoItem.missionItem.itemType isEqualToString:I_SOLUTION] )
		self.annoItem.missionItem.mandatory = MANDATORY_N;
	else
	{	
		ctrl = @"switch";
	}
	
	if ([self.annoItem.missionItem.itemType isEqualToString:I_MINE])
	{
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_0", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_1", nil),
            @"title",[NSNumber numberWithInt:P_ITEM_TYPE],@"tag",[[APPDEL itemType] valueForKey:self.annoItem.missionItem.itemType],@"detail",self.annoItem.missionItem.itemType,@"code",nil],
    //       [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_2", nil),
    //        @"title",[NSNumber numberWithInt:P_SHOW_TYPE],@"tag",[[APPDEL showType] valueForKey:self.annoItem.missionItem.showType],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_3", nil),
            @"title",[NSNumber numberWithInt:P_RANGE_AR],@"tag",[APPDEL rangeAR],@"db",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR],@"detail",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR], @"target",nil],
           nil],@"data",
          nil]
		 ];
	}
	else if ([self.annoItem.missionItem.itemType isEqualToString:I_BLACK])
	{
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_0", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_1", nil)
            ,@"title",[NSNumber numberWithInt:P_ITEM_TYPE],@"tag",[[APPDEL itemType] valueForKey:self.annoItem.missionItem.itemType],@"detail",self.annoItem.missionItem.itemType,@"code",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_4", nil)
            ,@"title",[NSNumber numberWithInt:P_RANGE_AR],@"tag",
            [APPDEL rangeAR],@"db",
            [NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR],@"detail",
            [NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR], @"target",nil],
           nil],@"data",
          nil]
		 ];
	}
    else if ([self.annoItem.missionItem.itemType isEqualToString:I_START])
	{
		[tableList addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_0", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_1", nil)
            ,@"title",[[APPDEL itemType] valueForKey:self.annoItem.missionItem.itemType],@"detail",self.annoItem.missionItem.itemType,@"code",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_5", nil)
            ,@"title",ctrl,@"ctrl",[[APPDEL mandatory] objectAtIndex:self.annoItem.missionItem.mandatory],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_6", nil)
            ,@"title",[[APPDEL showType] valueForKey:self.annoItem.missionItem.showType],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_7", nil)
            ,@"title",[NSNumber numberWithInt:P_RANGE_AR],@"tag",[APPDEL rangeAR],@"db",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR],@"detail",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR], @"target",nil],
           nil],@"data",
          nil]
         ];	}
	else 
	{
		[tableList addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_0", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_1", nil)
            ,@"title",[[APPDEL itemType] valueForKey:self.annoItem.missionItem.itemType],@"detail",self.annoItem.missionItem.itemType,@"code",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_5", nil)
            ,@"title",ctrl,@"ctrl",[[APPDEL mandatory] objectAtIndex:self.annoItem.missionItem.mandatory],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_6", nil)
            ,@"title",[NSNumber numberWithInt:P_SHOW_TYPE],@"tag",[[APPDEL showType] valueForKey:self.annoItem.missionItem.showType],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_7", nil)
            ,@"title",[NSNumber numberWithInt:P_RANGE_AR],@"tag",[APPDEL rangeAR],@"db",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR],@"detail",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.rangeAR], @"target",nil],
          
           nil],@"data",
          nil]
         ];
	}
	// 2 section
	if ([self.annoItem.missionItem.itemType isEqualToString:I_RADAR_BLACK]) // 현재 구현 안됨
	{
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_8", nil), @"group", 
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_9", nil)
            ,@"title",[NSNumber numberWithInt:P_BLACK_TIME],@"tag",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.blackTime],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_10", nil)
            ,@"title",[NSNumber numberWithInt:P_BLACK_CNT],@"tag",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.blackCnt],@"detail",nil],
           nil],@"data",
          nil]
         ];
	}
	else if ([self.annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_E])
	{
		int cnt = [[relatedItems objectForKey:I_TIMEOUT_S] count];
		if ( cnt == 1) 
			self.annoItem.missionItem.relationItemID = [[[relatedItems objectForKey:I_TIMEOUT_S] objectAtIndex:0] itemID];
		
		for (int i = 0 ; i < cnt ; i++)
		{
			MissionItem *relationItem = [[relatedItems objectForKey:I_TIMEOUT_S] objectAtIndex:i];
            //
			if (relationItem.itemID == self.annoItem.missionItem.relationItemID)
			{
				CLLocation *stPoint = [[[CLLocation alloc] initWithLatitude:(CLLocationDegrees)relationItem.latitude longitude:(CLLocationDegrees)relationItem.longitude] autorelease];
				CLLocation *edPoint = [[[CLLocation alloc] initWithLatitude:(CLLocationDegrees)self.annoItem.missionItem.latitude longitude:(CLLocationDegrees)self.annoItem.missionItem.longitude] autorelease];
				double distance = [stPoint distanceFromLocation:edPoint];
				
				self.annoItem.missionItem.effectiveRange = (int)distance;
                relationItem.relationItemID = self.annoItem.missionItem.itemID;
			}
		}
		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_8", nil)
          , @"group",
          [NSMutableArray arrayWithObjects:
//           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_11", nil)
//            ,@"title",[NSNumber numberWithInt:P_RELATION_ITEMID],@"tag",[NSString stringWithFormat:@"%d",self.annoItem.missionItem.relationItemID],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_12", nil)
            ,@"title",[NSString stringWithFormat:@"%d m",self.annoItem.missionItem.effectiveRange],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_13", nil)
            ,@"title",[NSNumber numberWithInt:P_EFFECTIVE_TIME],@"tag",[APPDEL sec2timeFormat:self.annoItem.missionItem.effectiveTime],@"detail",nil],
           nil],@"data",
          nil]
		 ];	
		
	}
	else if ([self.annoItem.missionItem.itemType isEqualToString:I_START] || [self.annoItem.missionItem.itemType isEqualToString:I_END])
	{
		UIFont *font = [UIFont systemFontOfSize:20];
		CGSize withinSize  = CGSizeMake(self.tableView.frame.size.width, 1000);
		CGSize size = [self.annoItem.missionItem.info sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
		int height = (size.height > 24 )  ? size.height + 30 : 75;
		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_8", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_14", nil)
            ,@"title",@"view",@"ctrl",[NSNumber numberWithInt:KEYIN_INFO],@"keyin",[NSNumber numberWithInt:height],@"height",
            self.annoItem.missionItem.info,@"detail", nil],
           nil],@"data",
          nil]
         ];
	}
	else if ([self.annoItem.missionItem.itemType isEqualToString:I_SOLUTION])
	{		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
           NSLocalizedString(@"builer_word_8", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_15", nil)
            ,@"title",[NSNumber numberWithInt:P_ITEM_GAME],@"tag",[APPDEL rangeAR],@"db",[[APPDEL itemGame] objectAtIndex: self.annoItem.missionItem.itemGame],@"detail",nil],
           nil],@"data",
          nil]
		 ];
	}
    else if([self.annoItem.missionItem.itemType isEqualToString:I_SIMPLE])			
	{  
		UIFont *font = [UIFont systemFontOfSize:20];
		CGSize withinSize  = CGSizeMake(self.tableView.frame.size.width, 1000);
		CGSize size = [self.annoItem.missionItem.info sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
		int height = (size.height > 24 )  ? size.height + 30 : 75;
		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_8", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_15", nil)
            ,@"title",[NSNumber numberWithInt:P_ITEM_GAME],@"tag",[APPDEL rangeAR],@"db",[[APPDEL itemGame] objectAtIndex: self.annoItem.missionItem.itemGame],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_23", nil),@"title",@"view",@"ctrl",
            [NSNumber numberWithInt:KEYIN_INFO],@"keyin",[NSNumber numberWithInt:height],@"height",self.annoItem.missionItem.info,@"detail",nil],
           nil],@"data",
          nil]
		 ];
	}
	else if(![self.annoItem.missionItem.itemType isEqualToString:I_QUIZ] && ![self.annoItem.missionItem.itemType isEqualToString:I_QUIZ20] &&
            ![self.annoItem.missionItem.itemType isEqualToString:I_STORE] && ![self.annoItem.missionItem.itemType isEqualToString:I_END] &&
            ![self.annoItem.missionItem.itemType isEqualToString:I_RANDOM] && ![self.annoItem.missionItem.itemType isEqualToString:I_MINE] &&
            ![self.annoItem.missionItem.itemType isEqualToString:I_BLACK] && ![self.annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_S])			
		
	{  
		UIFont *font = [UIFont systemFontOfSize:20];
		CGSize withinSize  = CGSizeMake(self.tableView.frame.size.width, 1000);
		CGSize size = [self.annoItem.missionItem.info sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
		int height = (size.height > 24 )  ? size.height + 30 : 75;
		
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_8", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_15", nil)
            ,@"title",[NSNumber numberWithInt:P_ITEM_GAME],@"tag",[APPDEL rangeAR],@"db",[[APPDEL itemGame] objectAtIndex: self.annoItem.missionItem.itemGame],@"detail",nil],
           [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"builer_word_24", nil),@"title",@"view",@"ctrl",
            [NSNumber numberWithInt:KEYIN_INFO],@"keyin",[NSNumber numberWithInt:height],@"height",self.annoItem.missionItem.info,@"detail",nil],
           nil],@"data",
          nil]
		 ];
	}
	
	//퀴즈,스무고개 
	int cnt = [annoItem.missionItem.itemQuizzes count];
	for (int i = 0; i < cnt; i++)
	{
		// 퀴즈,스무고개
		if ([self.annoItem.missionItem.itemType isEqualToString:I_QUIZ])
		{
     
			ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:i];
			int k_quiz = [[NSString stringWithFormat:@"%d%d",i,KEYIN_QUIZ] intValue];
			int k_answer = [[NSString stringWithFormat:@"%d%d",i,KEYIN_ANSWER] intValue];
			
			UIFont *font = [UIFont systemFontOfSize:20];
			CGSize withinSize  = CGSizeMake(self.tableView.frame.size.width, 1000);
			CGSize size = [itemQuiz.quiz sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
			int height = (size.height > 24 )  ? size.height + 30 : 75;
			
			[tableList addObject:
			 [NSDictionary dictionaryWithObjectsAndKeys:
              NSLocalizedString(@"builer_word_16", nil), @"group",
              [NSMutableArray arrayWithObjects:
               [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_17", nil)
                ,@"title",NSLocalizedString(@"builer_word_17", nil)
                ,@"placeholder", @"D",@"editingStyle",@"view",@"ctrl",[NSNumber numberWithInt:k_quiz],@"keyin",[NSNumber numberWithInt:height],@"height",itemQuiz.quiz,@"detail",itemQuiz,@"targetDel",nil],
               [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_18", nil)
                ,@"title",NSLocalizedString(@"builer_word_19", nil)
                ,@"placeholder",@"text",@"ctrl",[NSNumber numberWithInt:k_answer],@"keyin",itemQuiz.answer,@"detail",nil],
               nil],@"data",
              nil]
             ];
			
			
		}
	}
	
	if ([self.annoItem.missionItem.itemType isEqualToString:I_QUIZ])
	{
	
		[tableList addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"builer_word_20", nil), @"group",
          [NSMutableArray arrayWithObjects:
           [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"builer_word_21", nil)
            ,@"detail",@"I",@"editingStyle",@"Q",@"addType",nil],
           nil],@"data",
          nil]
         ];
	}
	NSLog(@"tableList:%@",tableList);
}
- (void)switchAction:(id)sender
{
	if ([sender isOn])
		annoItem.missionItem.mandatory = MANDATORY_Y;
	else
		annoItem.missionItem.mandatory = MANDATORY_N;
	
    
	// NSLog(@"switchAction: value = %d", [sender isOn]);
}


-(void)dataPickerDoneClick;
{
	[dataPicker removeFromSuperview];
	[dataPickerToolbar removeFromSuperview]; 
	
	
	if (dataPicker.tag == P_ITEM_TYPE) 
	{ //이인상 변경
		//annoItem.missionItem.itemType = [[[APPDEL itemType] allKeys] objectAtIndex:[dataPicker selectedRowInComponent:0]];
		//self.navigationItem.title = [[APPDEL itemType] valueForKey:annoItem.missionItem.itemType];
		annoItem.missionItem.itemType = [[APPDEL itemTypeKeys] objectAtIndex:[dataPicker selectedRowInComponent:0]];
		self.navigationItem.title = [[APPDEL itemTypeObjects] objectAtIndex:[dataPicker selectedRowInComponent:0]];
		
	}
	else if (dataPicker.tag == P_RELATION_ITEMID)	
	{
		MissionItem *relationItem = [[relatedItems objectForKey:I_TIMEOUT_S] objectAtIndex:[dataPicker selectedRowInComponent:0]];
		annoItem.missionItem.relationItemID = relationItem.itemID;
	}
	else if (dataPicker.tag == P_SHOW_TYPE)	
	{
		annoItem.missionItem.showType = [[[APPDEL showType] allKeys] objectAtIndex:[dataPicker selectedRowInComponent:0]];
	}
	else if (dataPicker.tag == P_RANGE_AR)	
	{
		annoItem.missionItem.rangeAR = [[[APPDEL rangeAR] objectAtIndex:[dataPicker selectedRowInComponent:0]] intValue];
	}
	else if (dataPicker.tag == P_EFFECTIVE_TIME)	
	{
		NSString *tt = [NSString stringWithFormat:@"00:%02d:%02d",[dataPicker selectedRowInComponent:0],[dataPicker selectedRowInComponent:1]];
		annoItem.missionItem.effectiveTime = [APPDEL timeFormat2sec:tt];
    }
	else if (dataPicker.tag == P_EFFECTIVE_RANGE)	
	{
		annoItem.missionItem.rangeAR = [[[APPDEL effectiveRange] objectAtIndex:[dataPicker selectedRowInComponent:0]] intValue];
	}
	else if (dataPicker.tag == P_ITEM_GAME)	
	{
		annoItem.missionItem.itemGame = [dataPicker selectedRowInComponent:0];
		//annoItem.missionItem.itemGame = [[[APPDEL itemGame] objectAtIndex:[dataPicker selectedRowInComponent:0]] intValue];
	}
	else if (dataPicker.tag == P_BLACK_TIME)	
	{
		annoItem.missionItem.blackTime = ([dataPicker selectedRowInComponent:0]+1) * 5 * 60;
	}
	else if (dataPicker.tag == P_BLACK_CNT)	
	{
		annoItem.missionItem.blackCnt = [[[APPDEL blackCnt] objectAtIndex:[dataPicker selectedRowInComponent:0]] intValue];
	}
    	
	[self makeTableSectionInfo];
	[self.tableView reloadData];
	
}

-(void)dataPickerCancelClick
{
 	[dataPicker removeFromSuperview];
	[dataPickerToolbar removeFromSuperview];	
}


- (void)delButtonClick:(id)sender
{
	
	NSArray *allControllers = self.navigationController.viewControllers;
	MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
	
	[missionBuilder.mission.mItems removeObject:self.annoItem.missionItem];
	[missionBuilder.theMapView removeAnnotation:self.annoItem];
	
	//DB 삭제
	MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	[missionItemDao delete:self.annoItem.missionItem];

	if ([annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_E] ||
        [annoItem.missionItem.itemType isEqualToString:I_TIMEOUT_S] ) {
        
        for (AnnoItem *anno in missionBuilder.theMapView.annotations) {
            if (anno.missionItem.itemID == annoItem.missionItem.relationItemID)
            {
                
                [missionBuilder.mission.mItems removeObject:anno.missionItem];
                [missionBuilder.theMapView removeAnnotation:anno];
                
                //DB 삭제
                MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
                [missionItemDao delete:anno.missionItem];
                break;
            }
        }
    }
    
	[self.navigationController popViewControllerAnimated:YES];

}

-(void)editCancelClick 
{
	[dataPicker removeFromSuperview];
	[dataPickerToolbar removeFromSuperview];	
	
	NSArray *allControllers = self.navigationController.viewControllers;
	MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
	
	missionBuilder.selectedAnno = self.loadItem;
	
	[self.navigationController popViewControllerAnimated:YES];
	
}

-(void)editSaveClick 
{
	[dataPicker removeFromSuperview];
	[dataPickerToolbar removeFromSuperview];	
	
	//미입력된 TextField 저장
	[self activeViewSave];
	[self activeFieldSave];
	
	
	if ([self dataCheck] == NO) return;
    
	NSArray *allControllers = self.navigationController.viewControllers;
	MissionBuilder *missionBuilder = [allControllers objectAtIndex:[allControllers count]-2];
	
	//DB 저장
	MissionItemDao *missionItemDao = [[[MissionItemDao alloc] init] autorelease];
	[missionItemDao save:self.annoItem.missionItem];
	
	
	//ItemQuizDao *itemQuizDao = [[ItemQuizDao alloc] init];
	ItemQuizDao *itemQuizDao = [[[ItemQuizDao alloc] init] autorelease];
	
	[itemQuizDao delete_itemID:self.annoItem.missionItem.missionID ItemID: self.annoItem.missionItem.itemID];
	
	for (int i = 0; i< [self.annoItem.missionItem.itemQuizzes count] ; i++) 
	{
		[itemQuizDao save:[self.annoItem.missionItem.itemQuizzes objectAtIndex:i]];
	}
	
	
	[missionBuilder.theMapView removeAnnotation:self.annoItem];
	[missionBuilder.theMapView addAnnotation:self.annoItem];	
	
	//[missionBuilder.mission.mItems removeObject:self.annoItem];
	//[missionBuilder.mission.mItems addObject:self.annoItem];
	
	[self.navigationController popViewControllerAnimated:YES];
    
}



- (EditableDetailCell *)newDetailCellWithTag:(NSInteger)tag
{
	EditableDetailCell *cell =nil;
	if (tag == LONG_TEXT) {
		cell = [[EditableDetailCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                         reuseIdentifier:C_TEXT_VIEW];
		[[cell textView] setDelegate:self];
        [[cell textView] setTag:tag];
        
	}
	else
	{
        cell = [[EditableDetailCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                         reuseIdentifier:nil];
		[[cell textField] setDelegate:self];
        [[cell textField] setTag:tag];
        
	}
	
	return cell;
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark tableView Protocol

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSDictionary *group = [tableList objectAtIndex:indexPath.section];
	NSMutableArray *cells = [group objectForKey:@"data"];
	NSDictionary *oneCell = [cells objectAtIndex:indexPath.row];
	NSString *style = [oneCell objectForKey:@"editingStyle"];
	
	if ([style isEqualToString:@"D"]) 
		return UITableViewCellEditingStyleDelete;
	else if ([style isEqualToString:@"I"]) 
		return UITableViewCellEditingStyleInsert;
	else
		return UITableViewCellEditingStyleNone;
	
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	/*
	 if (self.editing){
	 nameTextField.text = currEmployee.nameOfEmployee;
	 ageTextField.text = [NSString stringWithFormat:@"%d",currEmployee.ageOfEmployee];
	 departmentTextField.text = currEmployee.departmentOfEmployee;
	 self.view = editView;
	 } else {
	 currEmployee.nameOfEmployee = nameTextField.text;
	 currEmployee.ageOfEmployee = [ageTextField.text intValue];
	 currEmployee.departmentOfEmployee = departmentTextField.text;
	 
	 nameLabel.text = currEmployee.nameOfEmployee;
	 ageLabel.text = [NSString stringWithFormat:@"%d",currEmployee.ageOfEmployee];
	 departmentLabel.text = currEmployee.departmentOfEmployee;
	 
	 self.view = displayView;
	 }
	 */
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath{
	
	NSDictionary *group = [tableList objectAtIndex:indexPath.section];
	NSMutableArray *cells = [group objectForKey:@"data"];
	NSDictionary *oneCell = [cells objectAtIndex:indexPath.row];
	
	
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		[self.annoItem.missionItem.itemQuizzes removeObject:[oneCell objectForKey:@"targetDel"]];
		
		[self makeTableSectionInfo];
		[self.tableView reloadData];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		if ([[oneCell objectForKey:@"addType"] isEqualToString:@"Q"])	[self.annoItem.missionItem addItemQuiz];
		
		
		[self makeTableSectionInfo];
		[self.tableView reloadData];
	}

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return ([tableList count] == 0 ? 1 : [tableList count]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[tableList objectAtIndex:section] objectForKey:@"data"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
	return [[tableList objectAtIndex:section] objectForKey:@"group"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat ret = 40;
	
	int k = [[[[[tableList objectAtIndex:indexPath.section] objectForKey:@"data"] objectAtIndex:indexPath.row] objectForKey:@"keyin"] intValue];
	
	int ix =  k / 10;
	int keyin =  k % 10;
	
	if (keyin == KEYIN_INFO)
	{
		UIFont *font = [UIFont systemFontOfSize:20];
		CGSize withinSize  = CGSizeMake(tableView.frame.size.width, 1000);
		CGSize size = [self.annoItem.missionItem.info sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
		ret = (size.height > 24 )  ? size.height + 30 : 75;
		
	}
	else if (keyin == KEYIN_QUIZ)
	{
		ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:ix];
        
		UIFont *font = [UIFont systemFontOfSize:20];
		CGSize withinSize  = CGSizeMake(tableView.frame.size.width, 1000);
		CGSize size = [itemQuiz.quiz sizeWithFont:font constrainedToSize:withinSize lineBreakMode:UILineBreakModeWordWrap];
		ret = (size.height > 24 )  ? size.height + 30 : 75;
	}
	
	return ret;
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *group = [tableList objectAtIndex:indexPath.section];
	NSMutableArray *cells = [group objectForKey:@"data"];
	NSDictionary *oneCell = [cells objectAtIndex:indexPath.row];
    
	NSString *CellIdentifier = [NSString stringWithFormat: @"%@",oneCell.description];
	NSString *text = nil;
    
	EditableDetailCell *keyCell = nil;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
	}
	else
	{
		// the cell is being recycled, remove old embedded controls
		UIView *viewToRemove = nil;
		viewToRemove = [cell.contentView viewWithTag:kViewTag];
		if (viewToRemove)
			[viewToRemove removeFromSuperview];
	}
	
	
	
	//title = [oneCell objectForKey:@"title"];
	text = [oneCell objectForKey:@"detail"];
	//placeholder = [oneCell objectForKey:@"placeholder"];
	//tag = [[NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row] intValue];
	
	if ([[oneCell objectForKey:@"ctrl"] isEqualToString:@"view"])
	{
		keyCell = [[self newDetailCellWithTag:LONG_TEXT] autorelease];
		[keyCell.textView setBackgroundColor:[UIColor clearColor]];
        [keyCell.label setBackgroundColor:[UIColor clearColor]];
		keyCell.label.text = [oneCell objectForKey:@"title"];	
       
		if ([text isEqualToString:@""])
			[keyCell.textView becomeFirstResponder];
		else
			keyCell.textView.text = [oneCell objectForKey:@"detail"];
		keyCell.textView.tag = [[NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row] intValue];
        
	}
	else if ([[oneCell objectForKey:@"ctrl"] isEqualToString:@"text"])
	{
		keyCell = [[self newDetailCellWithTag:SHORT_TEXT] autorelease];
       // keyCell.frame = CGRectMake(160, 2, 160, tableView.rowHeight - 4);
        [keyCell.textField setBackgroundColor:[UIColor clearColor]];
        [keyCell.label setBackgroundColor:[UIColor clearColor]];
		[[keyCell label] setText:[oneCell objectForKey:@"title"]];		
        
		[[keyCell textField] setPlaceholder:[oneCell objectForKey:@"placeholder"]];
		[[keyCell textField] setText:[oneCell objectForKey:@"detail"]];
		
		//NSLog( @"detail:%@,textField:%@",[oneCell objectForKey:@"detail"],keyCell.textField.text);
 		keyCell.textField.tag = [[NSString stringWithFormat:@"%d%d",indexPath.section,indexPath.row] intValue];
		
	}
	else if ([[oneCell objectForKey:@"ctrl"] isEqualToString:@"switch"])
	{
        //[cell.textLabel setBackgroundColor:[UIColor clearColor]];
		//cell.textLabel.text = [oneCell objectForKey:@"title"];
        
        UILabel *lbltitle = [[UILabel alloc] init];
        lbltitle.frame = CGRectMake(5, 2, 110, tableView.rowHeight - 4);
        lbltitle.backgroundColor = [UIColor clearColor];
        lbltitle.textColor = RGBA(0, 0, 102, 1);
        lbltitle.font = [UIFont systemFontOfSize:16];
        [cell.contentView addSubview:lbltitle];
        [lbltitle release];
        lbltitle.text = [oneCell objectForKey:@"title"];
		[cell.contentView addSubview:self.switchCtl];
		if (self.annoItem.missionItem.mandatory == MANDATORY_Y) 
			[self.switchCtl setOn:YES animated:YES];
		else 
			[self.switchCtl setOn:NO animated:YES];
	}
	else 
	{
        UILabel *lbltitle = [[UILabel alloc] init];
        lbltitle.frame = CGRectMake(5, 2, 160, tableView.rowHeight - 4);
        lbltitle.backgroundColor = [UIColor clearColor];
        lbltitle.textColor = RGBA(0, 0, 102, 1);
        lbltitle.font = [UIFont systemFontOfSize:16];
        [cell.contentView addSubview:lbltitle];
        [lbltitle release];
        
        UILabel *lbldetail = [[UILabel alloc] init];
        lbldetail.frame = CGRectMake(165, 2, 160, tableView.rowHeight - 4);
        lbldetail.backgroundColor = [UIColor clearColor];
        lbldetail.textColor = [UIColor blackColor];
        lbldetail.font = [UIFont systemFontOfSize:16];
        [cell.contentView addSubview:lbldetail];
        [lbldetail release];

        
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        //cell.textLabel.text = [oneCell objectForKey:@"title"];
		//cell.detailTextLabel.text = [oneCell objectForKey:@"detail"];
        
        lbltitle.text = [oneCell objectForKey:@"title"];
        lbldetail.text = [oneCell objectForKey:@"detail"];
	}
	
	return (keyCell == nil ? cell : keyCell);
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[APPDEL hideKeyboard];
    
    NSDictionary *group = [tableList objectAtIndex:indexPath.section];
	NSMutableArray *cells = [group objectForKey:@"data"];
	NSDictionary *oneCell = [cells objectAtIndex:indexPath.row];
	
	[dataPicker setTag:([oneCell objectForKey:@"tag"] == nil ? -1 : [[oneCell objectForKey:@"tag"] intValue])];
    
    [dataPicker removeLabels];
	if (dataPicker.tag == P_EFFECTIVE_TIME)
	{
		[dataPicker addLabel:@"min" forComponent:0 forLongestString:@"min"];
		[dataPicker addLabel:@"sec" forComponent:1 forLongestString:@"sec"];
	}
        
   
    [dataPicker reloadAllComponents];	
    
	NSUInteger ret = [[oneCell objectForKey:@"db"] indexOfObject:[oneCell objectForKey:@"target"]];
	if (ret != NSNotFound) 
		[dataPicker selectRow:ret inComponent:0 animated:NO];
    
   
	if (dataPicker.tag > -1)
	{
        [[APPDEL window] addSubview:dataPickerToolbar];
        [dataPickerToolbar setFrame:CGRectMake(0,276,320,44)];
        [[APPDEL window] addSubview:dataPicker];
        [dataPicker setFrame:CGRectMake(0,320,320,160)];
        [dataPicker reloadAllComponents];
	}
    
	
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
	
	[self activeViewSave];
	
	CGFloat newTextHeight = [textView contentSize].height;
	if (newTextHeight != textHeight)
	{
		textHeight = newTextHeight;
		[self tableViewNeedsToUpdateHeight];
	}	
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	activeView = textView;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	activeField = textField;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[textView resignFirstResponder];
	[self activeViewSave];
	activeView = nil;
	
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[textField resignFirstResponder];
	[self activeFieldSave];
	activeField = nil;
	/*
     NSString *text = [textField text];
     
     switch ((textField.tag / 10) % 10 )
     {
     case ITEM_QUIZ:		
     {
     ItemQuiz *itemQuiz = [self.annoItem.missionItem.itemQuizzes objectAtIndex:(textField.tag/100)];
     
     switch (textField.tag % 10)
     {
     //case QUIZ: itemQuiz.quiz = (NSMutableString *)text;		break;
     case ANSWER: itemQuiz.answer = (NSMutableString *)text;		break;
     case Q_PROBABILITY: itemQuiz.probability = [text intValue];		break;
     }
     
     break;
     }
     case ITEM_REWARD:
     {
     ItemRnP *itemReward = [self.annoItem.missionItem.itemRewards objectAtIndex:(textField.tag/100)];
     
     switch (textField.tag % 10)
     {
     case R_INCREASE: itemReward.increase = [text intValue];		break;
     case R_PROBABILITY: itemReward.probability = [text intValue];		break;
     }
     
     break;
     }
     case ITEM_PENALTY:
     {
     ItemRnP *itemPenalty = [self.annoItem.missionItem.itemPenalties objectAtIndex:(textField.tag/100)];
     
     switch (textField.tag % 10)
     {
     case R_INCREASE: itemPenalty.increase = [text intValue];		break;
     case R_PROBABILITY: itemPenalty.probability = [text intValue];		break;
     }
     
     break;
     }
     }
     */
}
// done 클릭시 키보드 내리기
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text 
{ 
	if([text isEqualToString:@"\n"]) 
		[textView resignFirstResponder];
	return YES; 
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
#pragma mark pickerView Protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	if (pickerView.tag == P_EFFECTIVE_TIME) 
		return 2;
	else
		return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger cnt = 0;
	
	if (pickerView.tag == P_ITEM_TYPE) {
		cnt = [[[APPDEL itemType] allValues] count];
	}
	else if (pickerView.tag == P_RELATION_ITEMID){
		cnt = [[relatedItems objectForKey:I_TIMEOUT_S] count];
	}
	else if (pickerView.tag == P_SHOW_TYPE){
		cnt = [[[APPDEL showType] allValues] count];
	}
	else if (pickerView.tag == P_EFFECTIVE_TIME){
		if (component == 0) cnt = [self.min count];
		else if (component == 1) cnt = [self.sec count];
		
	}
	else if (pickerView.tag == P_ITEM_GAME){
		cnt = [[APPDEL itemGame] count];
	}
	else if (pickerView.tag == P_EFFECTIVE_RANGE){
		cnt = [[APPDEL effectiveRange] count];
	}
	else if (pickerView.tag == P_RANGE_AR){
		cnt = [[APPDEL rangeAR] count];
	}
	else if (pickerView.tag == P_BLACK_TIME){
		cnt = [[APPDEL blackTime] count];
	}
	else if (pickerView.tag == P_BLACK_CNT){
		cnt = [[APPDEL blackCnt] count];
	}
	
	return cnt;	
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *ret = nil; 
	
	if (pickerView.tag == P_ITEM_TYPE)
	{ 
		ret = [[APPDEL itemTypeObjects] objectAtIndex:row];
		NSLog(@"row:%d",row);
		//ret = [[[APPDEL itemType] allValues] objectAtIndex:row];
	}
	else if (pickerView.tag == P_RELATION_ITEMID)
	{
		MissionItem *relationItem = [[relatedItems objectForKey:I_TIMEOUT_S] objectAtIndex:row];
		ret = [NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"builer_word_22", nil),relationItem.itemID];
		[self.tableView reloadData];
	}
	else if (pickerView.tag == P_SHOW_TYPE)
	{
		ret = [[[APPDEL showType] allValues] objectAtIndex:row];
	}
	else if (pickerView.tag == P_EFFECTIVE_TIME)
	{
		if (component == 0) ret = [self.min objectAtIndex:row] ;
		else if (component == 1) ret = [self.sec objectAtIndex:row];
		
		//if (component == 0) ret = [NSStringString stringWithFormat:@"%@ min",[self.min objectAtIndex:row]] ;
		//else if (component == 1) ret = [NSString stringWithFormat:@"%@ sec",[self.sec objectAtIndex:row]];
	}
	else if (pickerView.tag == P_ITEM_GAME)
	{
		ret = [[APPDEL itemGame] objectAtIndex:row];
	}
	else if (pickerView.tag == P_EFFECTIVE_RANGE)
	{
		ret = [[APPDEL effectiveRange] objectAtIndex:row];
	}
	else if (pickerView.tag == P_RANGE_AR){
		ret = [[APPDEL rangeAR] objectAtIndex:row];
	}
	else if (pickerView.tag == P_BLACK_TIME){
		ret = [[APPDEL blackTime] objectAtIndex:row];
	}
	else if (pickerView.tag == P_BLACK_CNT){
		ret = [[APPDEL blackCnt] objectAtIndex:row];
	}
	
	
	return ret;
}

@end
