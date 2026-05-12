//
//  ARGeoViewController.m
//  ARKitDemo
//
//  Created by Zac White on 8/2/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import "ARGeoViewController.h"
#import "ARGeoCoordinate.h"
#import "MissionPlay.h"

@implementation ARGeoViewController

@synthesize centerLocation;

- (id)init {
	if (!(self = [super init])) return nil;
	
	self.delegate = self;
	
	self.scaleViewsBasedOnDistance = YES;
	self.minimumScaleFactor = .5;
	
	self.rotateViewsBasedOnPerspective = YES;
	
	isFirstGps = YES;
	
	return self;
}

- (void)viewDidLoad {
	[self addSpots];
    
    NSLog(@"ARGeoViewController:viewDidLoad");
    
	self.centerLocation = [APPDEL startPoint];
    
	
}
-(void) viewDidAppear:(BOOL)animated {
    [self startListening];
	NSLog(@"ARGeoViewController:viewDidAppear:startListening");
    /*
    timer = [[NSTimer scheduledTimerWithTimeInterval:1 / 50.0f
                                              target:self
                                            selector:@selector(onSchedule)
                                            userInfo:nil
                                             repeats:YES] retain];
    */
    [super viewDidAppear:animated];
}

- (void)startListening {
	
	[APPDEL locationManager].desiredAccuracy = kCLLocationAccuracyBest;
	[APPDEL locationManager].distanceFilter = kCLDistanceFilterNone;
	[[APPDEL locationManager] startUpdatingLocation];  
  
    
	[APPDEL locationManager].headingFilter = 1;
 
	[APPDEL locationManager].desiredAccuracy = kCLLocationAccuracyBest;
	
	[[APPDEL locationManager] startUpdatingHeading];
	
	[APPDEL locationManager].delegate = self;
	
	[super startListening];
}



- (void)onSchedule {
 
    CLLocation *temp = [self.centerLocation copy];
    self.centerLocation = temp;
    [temp release];

    [super onSchedule];
    radianPhone.transform = CGAffineTransformMakeRotation(self.centerCoordinate.azimuth);
}

#define BOX_WIDTH 150
#define BOX_HEIGHT 100

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate {
	
	CGRect theFrame = CGRectMake(0, 0, BOX_WIDTH, BOX_HEIGHT);
	UIView *tempView = [[UIView alloc] initWithFrame:theFrame];
	
	//tempView.backgroundColor = [UIColor colorWithWhite:.5 alpha:.3];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, BOX_WIDTH, 20.0)];
	titleLabel.backgroundColor = [UIColor colorWithWhite:.3 alpha:.8];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.text = coordinate.title;
	[titleLabel sizeToFit];
	
	titleLabel.frame = CGRectMake(BOX_WIDTH / 2.0 - titleLabel.frame.size.width / 2.0 - 4.0, 0, 
                                  titleLabel.frame.size.width + 8.0, titleLabel.frame.size.height + 8.0);
	
	UIImageView *pointView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
	NSString *imgFile;
    if (coordinate.annoItem.missionItem.mandatory == MANDATORY_Y)
    {
    	imgFile = [APPDEL itemMandatoryARFile:coordinate.annoItem.missionItem.itemType];
    }
    else
    {
    	imgFile = [APPDEL itemARFile:coordinate.annoItem.missionItem.itemType];
    }
    
	pointView.image = [UIImage imageNamed:imgFile];
	pointView.frame = CGRectMake((int)(BOX_WIDTH / 2.0 - pointView.image.size.width / 2.0), 
                                 (int)(BOX_HEIGHT / 2.0 - pointView.image.size.height / 2.0), 
                                 pointView.image.size.width, pointView.image.size.height);
	
	//[tempView addSubview:titleLabel];
	[tempView addSubview:pointView];
	
	[titleLabel release];
	[pointView release];
	
	return [tempView autorelease];
}

- (void)addSpots
{
	NSMutableArray *tempLocationArray = [[NSMutableArray alloc] initWithCapacity:10];
	
	CLLocation *tempLocation;
	ARGeoCoordinate *tempCoordinate;
	NSLog(@"%@",caller.mapAnnotations);
	for (AnnoItem *annoItem in caller.mapAnnotations) {
		tempLocation = [[CLLocation alloc] initWithLatitude:annoItem.missionItem.latitude longitude:annoItem.missionItem.longitude];
		tempCoordinate = [ARGeoCoordinate coordinateWithLocation:tempLocation];
		tempCoordinate.title = [[APPDEL itemType] valueForKey:annoItem.missionItem.itemType];
		tempCoordinate.annoItem = annoItem;
        //tempCoordinate.radialDistance;
        NSLog(@"coordinate %.0fm", tempCoordinate.radialDistance);
		[tempLocationArray addObject:tempCoordinate];
		[tempLocation release];
	}
	if([ar_coordinates count] > 0)
		[ar_coordinates removeAllObjects];
	if([ar_coordinateViews count] > 0)
		[ar_coordinateViews removeAllObjects];
	[self addCoordinates:tempLocationArray];
	[tempLocationArray release];
	
}

- (void)setCenterLocation:(CLLocation *)newLocation {
	[centerLocation release];
	centerLocation = [newLocation retain];
	
	for (ARGeoCoordinate *geoLocation in self.coordinates) {
		if ([geoLocation isKindOfClass:[ARGeoCoordinate class]]) {
			[geoLocation calibrateUsingOrigin:centerLocation];
			
			if (geoLocation.radialDistance > self.maximumScaleDistance) {
				self.maximumScaleDistance = geoLocation.radialDistance;
			}
		}
	}
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	//NSLog(@"newLocation.horizontalAccuracy:%f",newLocation.horizontalAccuracy);
    
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        
        if(isFirstGps) {
            if(newLocation.horizontalAccuracy < 0.0) return;
            isFirstGps = NO;
        }
        else {
            if(newLocation.horizontalAccuracy < 0 || newLocation.horizontalAccuracy > 100) return;
        }
        if (newLocation != oldLocation) {
            self.centerLocation = newLocation;
            NSLog(@"centerLocation:%f,%f",centerLocation.coordinate.latitude,centerLocation.coordinate.longitude);
          
            [super locationManager:(CLLocationManager *)manager
               didUpdateToLocation:(CLLocation *)newLocation
                      fromLocation:(CLLocation *)oldLocation];
        }
        
    }
}

- (void)viewDidUnload
{
    NSLog(@"ARGeoViewController:viewDidUnload");   
   // [APPDEL locationManager].delegate = nil;
    
   	[super viewDidUnload];
}

- (void)dealloc {
     NSLog(@"ARGeoViewController:dealloc");   
    [APPDEL locationManager].delegate = nil;
    self.centerLocation = nil;
    

	[super dealloc];
}
@end
