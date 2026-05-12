//
//  ItemQuizDao.h
//  TreasureHunter
//
//  Created by 인상 이 on 11. 3. 6..
//  Copyright 2011 세리정보기술. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "ItemQuiz.h"

@interface ItemQuizDao : BaseDao {

}
-(NSMutableArray *)selectAt:(NSString *)missionID  ItemID:(int)itemID;
-(ItemQuiz *)selectWithPK:(NSString *)missionID ItemID:(int)itemID Seq:(int)seq;
-(BOOL)insert:(ItemQuiz *)itemQuiz;
-(BOOL)update:(ItemQuiz *)itemQuiz;
-(BOOL)delete:(ItemQuiz *)itemQuiz;
-(BOOL)delete_itemID:(NSString *)missionID ItemID:(int)itemID;
-(BOOL)save:(ItemQuiz *)itemQuiz;

@end
