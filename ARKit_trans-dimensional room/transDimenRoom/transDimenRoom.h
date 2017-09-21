//
//  transDimenRoom.h
//  RealPet
//
//  Created by 郭艺帆 on 2017/8/29.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface transDimenRoom : SCNNode
@property (nonatomic, strong) SCNNode *walls;
@property (nonatomic, strong) SCNLight *light;

+(instancetype)transDimenRoomAtPosition:(SCNVector3)position;
-(BOOL)checkIfInRoom:(SCNVector3)position;
-(void)hideWalls:(BOOL)hidden;
@end
