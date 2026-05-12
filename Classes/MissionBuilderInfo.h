//
//  MissionBuilderInfo.h
//  TreasureHunter
//
//  Created by ejola on 11. 3. 5..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h> 


enum  {
	MISSION_TITLE = 100,
	MISSION_DESCRIPTION,
	MISSION_PLACE,
	MISSION_QUIZ,
	MISSION_ANSWER
}; 

@class Mission;
@interface MissionBuilderInfo : UITableViewController<UITextFieldDelegate,UITextViewDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate> 
{
	Mission *mission;
	UIDatePicker *datePicker;
	UIDatePicker *cntPicker;
	UIToolbar *pickerToolbar;
	UITextField *activeField;
	UITextView  *activeView;
	CGFloat textHeight;
    UIImage *badgeImg;
    UISwitch				*switchCtl;
//    MKReverseGeocoder *reversGeocoder;
    IBOutlet UITableView *mTableView;
       
}
@property (retain, nonatomic) IBOutlet UITableView *mTableView;

@property (nonatomic,retain) Mission *mission;
@property (nonatomic,retain) UIDatePicker *datePicker;
@property (nonatomic,retain) UIDatePicker *cntPicker;
@property (nonatomic,retain) UIToolbar *pickerToolbar;
@property (nonatomic,retain) UITextField *activeField;
@property (nonatomic,retain) UITextView  *activeView;

- (BOOL)dataCheck;
//- (void)getPlaceMark : (CLLocationCoordinate2D) coordinate;
- (void)getGooglePlaceMark : (CLLocationCoordinate2D) coordinate;
- (void)tableViewNeedsToUpdateHeight;
- (UIImage*) maskImage:(UIImage *)image maskt:(UIImage *)maskImage;
- (void)onClickBadgeImg;
@end
