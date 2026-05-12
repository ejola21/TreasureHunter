//
//  ARKViewController.h
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CMPopTipView.h"
#import "ARCoordinate.h"
#import "NoticAlertView.h"
#import "QuizPlayAlert.h"
#import "GamePlayAlert.h"

#define DEGREES_TO_RADIANS(d) (d * M_PI / 180)

@class MissionPlay;
@class MissionBuilder;
@class ItemRnP;

@protocol ARViewDelegate

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate;

@end


@interface ARViewController : UIViewController <UIAccelerometerDelegate, CLLocationManagerDelegate,CMPopTipViewDelegate> {
    
	UIAccelerometer *accelerometerManager;
	
	ARCoordinate *centerCoordinate;
	
	UIImagePickerController *cameraController;
	
	NSObject<ARViewDelegate> *delegate;
	NSObject<CLLocationManagerDelegate> *locationDelegate;
	NSObject<UIAccelerometerDelegate> *accelerometerDelegate;
	
	BOOL scaleViewsBasedOnDistance;
	double maximumScaleDistance;
	double minimumScaleFactor;
	
	BOOL rotateViewsBasedOnPerspective;
    BOOL shakeEnable;
	double maximumRotationAngle;
	
	MissionPlay *caller;
    int quizType;
    UIView *imgItemView;
    
@protected
	NSMutableArray *ar_coordinates;
	NSMutableArray *ar_coordinateViews;
    UIImageView *radianPhone;
@private
//	NSTimer *_updateTimer;
	
	UIView *ar_overlayView;
	UIButton *ar_infoView;
	UIButton *ar_infoView1;
    UIButton *ar_radar;
    UIImageView *radianItem;
  
	UIButton *mapButton;
	
	ARCoordinate *minDistItem;
	ARCoordinate *minDistItemInView;
    
	CLLocationDirection rawDirection;
	CLLocationDirection correctedDirection;

	MissionItem *outstandingItem;
    NSMutableArray *randItems;
    NSMutableString *itemTypeString;
    
    NoticAlertView *noticAlertView;
    GamePlayAlert *gamePlayAlert;
    QuizPlayAlert *quizAlert;
}

@property (readonly) NSArray *coordinates;


@property BOOL scaleViewsBasedOnDistance;
@property double maximumScaleDistance;
@property double minimumScaleFactor;

@property BOOL rotateViewsBasedOnPerspective;
@property double maximumRotationAngle;
@property (nonatomic, retain) NSMutableArray *randItems;
@property (nonatomic, retain) MissionPlay *caller;

//adding coordinates to the underlying data model.
- (void)addCoordinate:(ARCoordinate *)coordinate;
- (void)addCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated;
- (void)addCoordinates:(NSArray *)newCoordinates;


//removing coordinates
- (void)removeCoordinate:(ARCoordinate *)coordinate;
- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated;

- (void)removeCoordinates:(NSArray *)coordinates;

- (void)startListening;
- (void)onSchedule;
//- (void)updateLocations:(NSTimer *)timer;
- (void)updateLocations;

- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(ARCoordinate *)coordinate;

- (BOOL)viewportContainsCoordinate:(ARCoordinate *)coordinate;

- (void)onMapView:(id)sender;


- (void)getItemAnimation;
- (void)getItem:(MissionItem *) aItem;
- (void)missionSuccess:(MissionItem *) aItem;
- (void)mapInfoUpdate:(BOOL) isMissionEnd;


- (void)didReceiveFinished:(NSString *)result;

- (void)stopTimer;
- (void)startTimer;

- (void)playQuiz :(MissionItem *)aItem;
- (void)itemGetAlert:(int)itemKind Title:(NSString *)title Message:(NSString *)message;


@property (nonatomic, retain) UIImagePickerController *cameraController;

@property (nonatomic, assign) NSObject<ARViewDelegate> *delegate;
@property (nonatomic, assign) NSObject<CLLocationManagerDelegate> *locationDelegate;
@property (nonatomic, assign) NSObject<UIAccelerometerDelegate> *accelerometerDelegate;

@property (retain) ARCoordinate *centerCoordinate;

@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) UIView *imgItemView;

@property (nonatomic, retain)	NSArray			*colorSchemes;
@property (nonatomic, retain)	NSDictionary	*contents;
@property (nonatomic, retain)	id				currentPopTipViewTarget;
@property (nonatomic, retain)	NSMutableArray	*visiblePopTipViews;


@end
