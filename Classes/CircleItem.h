#import <MapKit/MKCircle.h>
#import "TreasureHunterAppDelegate.h"

@class MissionItem;
//@class TreasureHunterAppDelegate;

@interface CircleItem : MKCircle
{
	MissionItem *missionItem;
}

@property (nonatomic,retain) MissionItem *missionItem;

@end
