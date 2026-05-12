//
//  ItemQuiz.h
//  TreasureHunter
//
//  Created by noh jh on 11. 2. 14..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ItemQuiz : NSObject<NSCopying> {
	NSMutableString		*missionID;
	int								itemID;
	int								seq;
	NSMutableString		*quiz;
	NSMutableString		*answer;
	int								probability;
}

@property (nonatomic,retain) NSMutableString *missionID;
@property (assign) int itemID;
@property (assign) int seq;
@property (nonatomic,retain) NSMutableString *quiz;
@property (nonatomic,retain) NSMutableString *answer;
@property (assign) int probability;

@end
