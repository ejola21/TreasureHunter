//
//  MissionBuilderDetail.h
//  TreasureHunter
//
//  Created by noh jh on 11. 1. 30..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class	EditableDetailCell;
@class	TreasureHunterAppDelegate;
@class	AnnoItem;
@class	MissionBuilder;
@class  MissionBuilderDetail;
@class  LabeledPickerView;

#define UNICHAR_INT(a) (int)((unichar)(a) - (unichar)'A' + 17)

// 피커 구분 tag
enum  {
	P_ITEM_TYPE = 0,
	P_SHOW_TYPE,
	P_RANGE_AR,
	P_EFFECTIVE_TIME,
	P_RELATION_ITEMID,
	P_EFFECTIVE_RANGE,
	P_ITEM_GAME,
	P_REWARD,
	P_PENALTY,
	P_BLACK_TIME,
	P_BLACK_CNT,
	
};

//미션디자인의 tag2 자리 tag
enum  {
	ITEM_END,
	ITEM_START,
	ITEM_SIMPLE,
	ITEM_QUIZ,
	ITEM_REWARD,
	ITEM_PENALTY
}; 
//미션디자인의 3 자리 tag
enum {
    KEYIN_QUIZ = 1,
    KEYIN_ANSWER,
		KEYIN_INFO
  /*  Q_PROBABILITY,
    REWARD,
		R_INCREASE,
		R_PROBABILITY,
		PENALTY,
    P_INCREASE,
		P_PROBABILITY
	 */
};

//  Constants representing the various sections of our grouped table view.
//
enum {
    TitleSection,
    AuthorSection,
    YearSection,
    ImageSection
};

 
@interface MissionBuilderDetail : UITableViewController<UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate,UITextViewDelegate> {
	AnnoItem		*annoItem;
	AnnoItem    *loadItem; //편집 취소용 최초로 load 된 Anno
	//MissionItem *missionItem;
	//NSMutableArray  *itemRewards;
	//NSMutableArray  *itemQuizs;
	//UITableView* _tableView;

	LabeledPickerView *dataPicker;
	//UIDatePicker *datePicker;
	UIToolbar *dataPickerToolbar;
	NSMutableArray *tableSection;
	UISwitch				*switchCtl;
	UITextView			*activeView;
	UITextField			*activeField;
	CGFloat				textHeight;
	NSDictionary *relatedItems;
	
	NSMutableArray *min;
	NSMutableArray *sec;
	
	
	NSMutableArray *tableList;
	
	//BOOL keyboardVisible;
	
	//EditableDetailCell *longText;
	//EditableDetailCell *shortText;
	//EditableDetailCell *numText;
}
@property (nonatomic,retain) AnnoItem *annoItem;
@property (nonatomic,retain) AnnoItem *loadItem;

//@property (nonatomic,retain) MissionItem *missionItem;
//@property (nonatomic,retain) NSMutableArray *itemQuizs;
//@property (nonatomic,retain) NSMutableArray *itemRewards;

@property (nonatomic,retain) LabeledPickerView *dataPicker;
//@property (nonatomic,retain) UIDatePicker *datePicker;
@property (nonatomic,retain) UIToolbar *dataPickerToolbar;
@property (nonatomic,retain) NSMutableArray *tableSection;
@property (nonatomic,retain) NSMutableArray *min;
@property (nonatomic,retain) NSMutableArray *sec;


- (EditableDetailCell *)newDetailCellWithTag:(NSInteger)tag;
- (void)makeTableSectionInfo;
- (void)activeViewSave;
- (void)activeFieldSave;
- (BOOL)dataCheck;

@end
