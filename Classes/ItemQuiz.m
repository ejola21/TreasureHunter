//
//  ItemQuiz.m
//  TreasureHunter
//
//  Created by noh jh on 11. 2. 14..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ItemQuiz.h"


@implementation ItemQuiz

@synthesize missionID,itemID,seq,quiz,answer,probability;

- (id) copyWithZone: (NSZone*) zone
{
	ItemQuiz *itemQuiz = [[[self class] allocWithZone:zone] init];
	
	itemQuiz.missionID = self.missionID;
	itemQuiz.itemID = self.itemID;
	itemQuiz.seq = self.seq;
	itemQuiz.quiz = self.quiz;
	itemQuiz.answer = self.answer;
	itemQuiz.probability = self.probability;

	return itemQuiz;
}

-(id)init
{
	self = [super init];
	if (self != nil) {
	
	
	}
	return self;
}


-(void)dealloc
{
	self.missionID =nil;
//	self.itemID = nil;
	self.quiz =nil;
	self.answer = nil;
	[super dealloc];
}

@end
