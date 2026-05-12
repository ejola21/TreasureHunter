//
//  ItemRnPInPlay.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 5. 7..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ItemRnPInPlay : NSObject {
	NSMutableString		*missionID;
	NSMutableString		*playerID;
    NSMutableString		*itemType;
	int                 ableCnt;
	NSDate              *ableTime;
	NSDate				*acquiredTime;    //획득시간
}

@property (nonatomic,retain) NSMutableString *missionID;
@property (nonatomic,retain) NSMutableString *playerID;
@property (nonatomic,retain) NSMutableString *itemType;
@property (assign) int ableCnt;
@property (nonatomic,retain) NSDate	*ableTime;
@property (nonatomic,retain) NSDate	*acquiredTime;

@end
