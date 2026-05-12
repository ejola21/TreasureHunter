//
//  AnnoQuiz.m
//  TreasureHunter
//
//  Created by noh jh on 11. 1. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AnnoItem.h"
#import "MissionItem.h"
#import "ItemQuiz.h"


@implementation AnnoItem
@synthesize missionItem,tag,coordinate;//, itemDetail = _itemDetail;
//@synthesize coordinate, title, subtitle,indexnumber,imageFile, missionItem = _missionItem, itemDetail = _itemDetail;
- (id) copyWithZone: (NSZone*) zone
{
	AnnoItem *annoItemCopy = [[[self class] allocWithZone: zone] init];
	
	//annoItemCopy.missionItem = self.missionItem;
	
	// engineCopy는 copy에 의해 생성된 것이므로 memory management rule에 의하여 release까지 책임을 져야 한다.
	// 여기에서는 autorelease를 걸어주었다.
	MissionItem * missionItemCopy = [[self.missionItem copy] autorelease];
	annoItemCopy.missionItem = missionItemCopy;
	
	
	return annoItemCopy;
}

-(id)init
{
	self = [super init];
	if (self != nil) {
		
		missionItem = [[MissionItem alloc] init];
		
		
		//[_missionItem retain]
	}
	return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{

  self.missionItem.longitude = newCoordinate.longitude;
  self.missionItem.latitude = newCoordinate.latitude;
}

- (CLLocationCoordinate2D)coordinate;
{
	CLLocationCoordinate2D theCoordinate;
	
	theCoordinate.latitude = self.missionItem.latitude;
	theCoordinate.longitude = self.missionItem.longitude;
	return theCoordinate; 
}


// required if you set the MKPinAnnotationView's "canShowCallout" property to YES
- (NSString *)title
{
	NSString * rtn = [NSString stringWithFormat:@"%@ %dm",[[APPDEL itemType] valueForKey:self.missionItem.itemType] ,self.missionItem.rangeAR];
	return rtn;
}

// optional
- (NSString *)subtitle
{	
	NSMutableString *rtn=nil;
	//NSLog(@"array count:%d",[itemQuizs count]);
	if ([self.missionItem.itemQuizzes count] > 0) {
		ItemQuiz *itemQuiz = [missionItem.itemQuizzes objectAtIndex:0];
		rtn = itemQuiz.quiz;
	}
	
	return rtn;	
}

/*
-(id)initWithCoordinates:(CLLocationCoordinate2D)location placeName: placeName
																					description:description indexnum:indexnum imageFileLoc:imageFileLoc
{
	
	self = [super init];
	if (self != nil) 
	{
    imageFile=imageFileLoc;
    [imageFile retain];
    indexnumber=indexnum;
    [indexnumber retain];
    coordinate = location;
    title = placeName;
    [title retain];
    subtitle = description;
    [subtitle retain];
	}
	return self;
}
*/

- (void)dealloc
{
	self.missionItem = nil;

	[super dealloc];
}


@end
