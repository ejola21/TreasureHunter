//
//  MissionMake.h
//  TreasureHunter
//
//  Created by noh jh on 10. 11. 21..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MultiPickerView.h"
#import "CircleItem.h"

//#import "AnnoItem.h"
//#import "WildcardGestureRecognizer.h"
//#import "TreasureHunterAppDelegate.h"
//#import "MissionItem.h"
//#import "ItemQuiz.h"
//#import "ItemRnP.h"


@class MissionBuilderDetail;
@class Mission;
@class AnnoItem;
@class TreasureHunterAppDelegate;
@class MissionItemDao;

@interface MissionBuilder : UIViewController<MultiPickerDelegate,MKMapViewDelegate,CLLocationManagerDelegate,UIGestureRecognizerDelegate> {
	
	AnnoItem *selectedAnno;
	AnnoItem *lastAnno;
    AnnoItem *lastAnno2;
	Mission *mission;
    NSArray *pickerSelection;
    NSMutableArray *mapOverlays;
     
	MKMapView *theMapView;	
	MultiPickerView *itemPicker;
	UIToolbar *itemPickerToolbar;
    UIActivityIndicatorView *indicator_;
  	CLLocationCoordinate2D recvCoord;
}

@property (nonatomic, retain) IBOutlet MKMapView *theMapView;
@property (nonatomic, retain) MultiPickerView *itemPicker;
@property (nonatomic, retain) UIToolbar *itemPickerToolbar;


@property (nonatomic, retain) AnnoItem *selectedAnno;
@property (nonatomic, retain) AnnoItem *lastAnno;
@property (nonatomic, retain) AnnoItem *lastAnno2;
@property (nonatomic, retain) Mission *mission;
//@property (nonatomic, retain) CLLocation *startPoint;

+ (CGFloat)annotationPadding;
+ (CGFloat)calloutHeight;
- (void)loadBulidingMission;

- (void)openItemPicker:(UITapGestureRecognizer *)gestureRecognizer;

- (void)overlayRefresh;
- (BOOL)dataCheck;
- (void)editSaveClick; 
- (void)editCancelClick;
- (BOOL)localdbInput:(int) status;
- (void)gotoLocation;
- (void)gotoCurrentLocation;
@end
