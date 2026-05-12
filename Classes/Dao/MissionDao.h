#import <Foundation/Foundation.h>
#import "BaseDao.h"
#import "Mission.h"

@interface MissionDao : BaseDao {
}

-(NSMutableArray *)selectAll;
-(Mission *)selectWithPK:(NSString *)missionID;
-(BOOL)insert:(Mission *)mission;
-(BOOL)update:(Mission *)mission;
-(BOOL)save:(Mission *)mission;
-(BOOL)deleteAt:(NSString *)missionID;
-(BOOL)delete:(Mission *)mission;
-(NSMutableArray *)selectMissionStatus:(int)status;
@end
