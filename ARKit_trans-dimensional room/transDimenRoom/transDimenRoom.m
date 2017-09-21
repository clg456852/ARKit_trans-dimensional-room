//
//  transDimenRoom.m
//  RealPet
//
//  Created by 郭艺帆 on 2017/8/29.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "transDimenRoom.h"
#import "transDimenStruct.h"
#import <GLKit/GLKit.h>

#define DTG(x) GLKMathDegreesToRadians((x))
@implementation transDimenRoom

CGFloat sideLength = WALL_LENGTH;
CGFloat halfSideLength = WALL_LENGTH * 0.5;
CGFloat halfWallHeight = WALL_HEIGHT * 0.5;
CGFloat yFix = WALL_WIDTH;

+(instancetype)transDimenRoomAtPosition:(SCNVector3)position{
    transDimenRoom *wrapperNode = [transDimenRoom new];
    
    SCNNode *walls = [SCNNode new];
    walls.name = @"walls";

    
    SCNNode *backWall = [transDimenStruct wallSegmentNodWithLength:sideLength height:WALL_HEIGHT maskRightSide:YES];
    backWall.eulerAngles = SCNVector3Make(0,DTG(90), 0);
    //TODO: change 1.5*wall_length to a variable
    backWall.position = SCNVector3Make(0, halfWallHeight - yFix, -halfSideLength);
    backWall.name = @"backWall";
    backWall.castsShadow = NO;
    [walls addChildNode:backWall];
    
    SCNNode *leftWall = [transDimenStruct wallSegmentNodWithLength:sideLength height:WALL_HEIGHT maskRightSide:YES];
    leftWall.eulerAngles = SCNVector3Make(0, DTG(-180), 0);
    leftWall.position = SCNVector3Make(-halfSideLength, halfWallHeight - yFix, 0);
    leftWall.name = @"leftWall";
    leftWall.castsShadow = NO;
    [walls addChildNode:leftWall];
    
    SCNNode *rightWall = [transDimenStruct wallSegmentNodWithLength:sideLength height:WALL_HEIGHT maskRightSide:YES];
    rightWall.position = SCNVector3Make(halfSideLength, halfWallHeight - yFix, 0);
    rightWall.name = @"rightWall";
    rightWall.castsShadow = NO;
    [walls addChildNode:rightWall];
    
    CGFloat doorSideLength = (sideLength - DOOR_WIDTH) * 0.5;
    
    SCNNode *leftDoorSide = [transDimenStruct wallSegmentNodWithLength:doorSideLength height:WALL_HEIGHT maskRightSide:YES];
    leftDoorSide.eulerAngles = SCNVector3Make(0, DTG(-90), 0);
    leftDoorSide.position = SCNVector3Make(-halfSideLength + 0.5*doorSideLength ,halfWallHeight - yFix,halfSideLength-0.01);
    leftDoorSide.name = @"leftDoorSide";
    [walls addChildNode:leftDoorSide];
    
    SCNNode *rightDoorSide = [transDimenStruct wallSegmentNodWithLength:doorSideLength height:WALL_HEIGHT maskRightSide:YES];
    rightDoorSide.eulerAngles = SCNVector3Make(0, DTG(-90), 0);
    rightDoorSide.position = SCNVector3Make(halfSideLength - 0.5*doorSideLength,halfWallHeight - yFix,halfSideLength-0.01);
    rightDoorSide.name = @"rightDoorSide";
    [walls addChildNode:rightDoorSide];
    
    SCNNode *upperDoorSide = [transDimenStruct wallSegmentNodWithLength:DOOR_WIDTH height:WALL_HEIGHT - DOOR_HEIGHT maskRightSide:YES];
    upperDoorSide.eulerAngles = SCNVector3Make(0, DTG(-90), 0);
    upperDoorSide.position = SCNVector3Make(0, WALL_HEIGHT - (WALL_HEIGHT - DOOR_HEIGHT)/2 - yFix, halfSideLength-0.01);
    upperDoorSide.name = @"upperDoorSide";
    [walls addChildNode:upperDoorSide];
    
    //roof and floor
    SCNNode *floor = [transDimenStruct planeWithMaskUpperSide:NO];
    floor.castsShadow = NO;
    floor.name = @"floor";
    floor.position = SCNVector3Make(0, -yFix, 0);
    [walls addChildNode:floor];
    SCNNode *roof = [transDimenStruct planeWithMaskUpperSide:YES];
    roof.castsShadow = NO;
    roof.position = SCNVector3Make(0, WALL_HEIGHT - 2*yFix, 0);
    roof.name = @"roof"; 
    [walls addChildNode:roof];
    
    //door frame
    SCNNode *doorFrame = [transDimenStruct doorFrame];
    doorFrame.name = @"doorFrame";
    doorFrame.position = SCNVector3Make(0,-yFix, halfSideLength-WALL_WIDTH+0.001);
    [walls addChildNode:doorFrame];
    
    //inner structs
    SCNNode *innerStructs = [transDimenStruct innnerStructs];
    innerStructs.name = @"innnerStructs";
    innerStructs.position = SCNVector3Make(0, -yFix + 0.001, 0);
    [walls addChildNode:innerStructs];
    
    walls.position = SCNVector3Make(0, 0, -halfSideLength);
    [wrapperNode addChildNode:walls];
    wrapperNode.walls = walls;
    wrapperNode.position = position;
    [self node:wrapperNode enableCastShadows:NO];
//    [self node:upperDoorSide enableCastShadows:YES];
//    [self node:leftDoorSide enableCastShadows:YES];
//    [self node:rightDoorSide enableCastShadows:YES];
    [wrapperNode setupAmbientLight];
    return wrapperNode;
}
-(BOOL)checkIfInRoom:(SCNVector3)position{
    return NO;
}
-(void)hideWalls:(BOOL)hidden{
    SCNNode *floor = [self.walls childNodeWithName:@"floor" recursively:YES];
    SCNNode *doorFrame = [self.walls childNodeWithName:@"doorFrame" recursively:YES];
    
    [self.walls enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if ((child != floor && ![floor.childNodes containsObject:child]) &&
            (child != doorFrame && ![doorFrame.childNodes containsObject:child])) {
            child.hidden = hidden;
        }
    }];
}
-(void)setupAmbientLight{
    //when user walk inside trans-dimension room, add a ambient light to illuminate inner structs
    SCNLight *ambientLight = [SCNLight light];
    ambientLight.type = SCNLightTypeAmbient;
    ambientLight.intensity = 100;
    SCNNode *node = [SCNNode new];
    node.name = @"ambientLight";
    node.light = ambientLight;
    node.position = SCNVector3Make(halfSideLength, WALL_HEIGHT * 0.5, halfSideLength);
    [_walls addChildNode:node];
}

+(void)node:(SCNNode*)node enableCastShadows:(BOOL)enable{
    node.castsShadow = enable;
    [node enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        [self node:child enableCastShadows:enable];
    }];
}
@end
