//
//  ARGeoViewController.h
//  ARKitDemo
//
//  Created by Zac White on 8/2/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARViewController.h"
#import "TreasureHunterAppDelegate.h"
#import "AnnoItem.h"
#import "MissionItem.h"
#import "ItemQuiz.h"

@interface ARGeoViewController : ARViewController <ARViewDelegate> {
	CLLocation *centerLocation;
//	NSTimer *timer;
@private
	BOOL isFirstGps;
}

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate;
- (void)addSpots;

//- (void)onSchedule;

@property (nonatomic, retain) CLLocation *centerLocation;

@end
