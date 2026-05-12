//
//  AnnoQuiz.h
//  TreasureHunter
//
//  Created by noh jh on 11. 1. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "TreasureHunterAppDelegate.h"

@class MissionItem;
//@class TreasureHunterAppDelegate;

//@interface AnnoItem : MKPlacemark <MKAnnotation,NSCopying>
@interface AnnoItem : NSObject <MKAnnotation,NSCopying>
{
	MissionItem *missionItem;
	
	NSString *title;
	NSString *subtile;
	NSString *imageFile;
	NSInteger tag;	
		
}

@property (nonatomic,readwrite,assign) CLLocationCoordinate2D coordinate;

@property (nonatomic,retain) MissionItem *missionItem;

@property (assign) NSInteger tag;

//@property (assign) ItemDetail itemDetail;

//@property (nonatomic,retain) NSString *title;
//@property (nonatomic,retain) NSString *subtitle;
//@property (nonatomic,retain) NSString *imageFile;


//- (MissionItem *) initMissionItem;
	

@end
