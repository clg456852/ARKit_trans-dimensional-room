//
//  tranDimenStruct
//  RealPet
//
//  Created by 郭艺帆 on 2017/8/29.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <SceneKit/SceneKit.h>

#define WALL_WIDTH 0.02
#define WALL_HEIGHT  2.5
#define WALL_LENGTH 2.5

#define DOOR_WIDTH 0.5
#define DOOR_HEIGHT 1.5

@interface transDimenStruct: SCNNode
+(SCNNode*)planeWithMaskUpperSide:(BOOL)isMaskUpper;
+(SCNNode*)wallSegmentNodWithLength:(CGFloat)length height:(CGFloat)height maskRightSide:(BOOL) isMaskRightSide;
+(SCNNode*)doorFrame;
+(SCNNode*)innnerStructs;
+(BOOL)checkIfUserInRoom;
@end
