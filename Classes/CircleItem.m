#import "CircleItem.h"
#import "MissionItem.h"

@implementation CircleItem
@synthesize missionItem;

- (id) copyWithZone: (NSZone*) zone
{
	CircleItem *circleItemCopy = [[[self class] allocWithZone: zone] init];
	MissionItem * missionItemCopy = [[self.missionItem copy] autorelease];
	circleItemCopy.missionItem = missionItemCopy;
	
	
	return circleItemCopy;
}

-(id)init
{
	self = [super init];
	if (self != nil) {
		
		missionItem = [[MissionItem alloc] init];
		
	}
	return self;
}

- (void)dealloc
{
	self.missionItem = nil;

	[super dealloc];
}


@end
