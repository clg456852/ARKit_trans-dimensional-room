//
//  ViewController.m
//  ARKit_trans-dimensional room
//
//  Created by 郭艺帆 on 2017/9/20.
//  Copyright © 2017年 ooOlly. All rights reserved.
//

#import "ViewController.h"
#import "transDimenRoom.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (nonatomic, strong) NSMutableDictionary<NSUUID*, SCNNode*> *planes;
@property (nonatomic, strong) SCNMaterial *gridMaterial;
@property (nonatomic, strong) id cameraContents;
@property (nonatomic, assign) BOOL isCameraBackground;
@property (nonatomic, strong) transDimenRoom *room;
@property (nonatomic, assign) BOOL stopDetectPlanes;
@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [SCNScene new];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    //Grid to identify plane detected by ARKit
    _gridMaterial = [SCNMaterial material];
    _gridMaterial.diffuse.contents = [UIImage imageNamed:@"art.scnassets/grid.png"];
    //when plane scaling large, we wanna grid cover it over and over
    _gridMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    _gridMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    
    _planes = [NSMutableDictionary dictionary];
    
    //tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(placeTransDimenRoom:)];
    [self.sceneView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - place room
-(void)placeTransDimenRoom:(UITapGestureRecognizer*)tap{
    CGPoint point = [tap locationInView:self.sceneView];
    NSArray<ARHitTestResult*> *results = [self.sceneView hitTest:point
                                                          types:ARHitTestResultTypeExistingPlaneUsingExtent|ARHitTestResultTypeEstimatedHorizontalPlane];
    simd_float3 position = results.firstObject.worldTransform.columns[3].xyz;
    if(!_room){
        _room = [transDimenRoom transDimenRoomAtPosition:SCNVector3FromFloat3(position)];
        _room.name = @"room";
        [self.sceneView.scene.rootNode addChildNode:_room];
    }
    _room.position = SCNVector3FromFloat3(position);
    _room.eulerAngles = SCNVector3Make(0, self.sceneView.pointOfView.eulerAngles.y, 0);
    
    _stopDetectPlanes = YES;
    [_planes enumerateKeysAndObjectsUsingBlock:^(NSUUID * _Nonnull key, SCNNode * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj removeFromParentNode];
    }];
    [_planes removeAllObjects];
    
    //TODO:keep room door looking at user
}
- (void)changeBackground:(BOOL)needcCustomBackground{
        if (!self.sceneView.scene.background.contents) {
            return;
        }
        if (!_cameraContents) {
            _cameraContents = self.sceneView.scene.background.contents;
        }
        if (needcCustomBackground) {
            self.sceneView.scene.background.contents = [UIImage imageNamed:@"art.scnassets/skybox01_cube.png"];
        }else{
            self.sceneView.scene.background.contents = _cameraContents;
        }
        _isCameraBackground = needcCustomBackground;
}
-(void)handleUserInRoom:(BOOL)isUserInRoom{
    @synchronized(self){
        static BOOL alreadyInRoom = NO;
        if (alreadyInRoom == isUserInRoom) {
            return;
        }
        [self changeBackground:isUserInRoom];
        [_room hideWalls:isUserInRoom];
        alreadyInRoom = isUserInRoom;

    }
}
#pragma mark - ARSCNViewDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time{
    if (_room.presentationNode) {

        SCNVector3 position = self.sceneView.pointOfView.presentationNode.worldPosition;

        SCNVector3 roomCenter = _room.walls.worldPosition;
        SCNVector3 roomCenter1 = [_room convertPosition:SCNVector3Make(0, 0, -2.5/2) toNode:nil];
        
        CGFloat distance = GLKVector3Length(GLKVector3Make(position.x - roomCenter.x, 0, position.z - roomCenter.z));
        
        //User walk into room
        //        if (positionRelativeToRoom.x > -2.5/2 && positionRelativeToRoom.x < 2.5/2) {
        //            if (positionRelativeToRoom.z < 0 && positionRelativeToRoom.z > -2.5) {
        if (distance < 1){
            NSLog(@"In room");
            [self handleUserInRoom:YES];
            return;
        }
        //            }
        //        }
        //User is outside of room
        [self handleUserInRoom:NO];
        
    }
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if ([anchor isKindOfClass:[ARPlaneAnchor class]] && !_stopDetectPlanes){
        NSLog(@"detected plane");
        [self addPlanesWithAnchor:(ARPlaneAnchor*)anchor forNode:node];
        [self postInfomation:@"touch ground to place room"];
    }
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]){
        NSLog(@"updated plane");
        [self updatePlanesForAnchor:(ARPlaneAnchor*)anchor];
    }
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]){
        NSLog(@"removed plane");
        [self removePlaneForAnchor:(ARPlaneAnchor*)anchor];
    }
}
- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}
#pragma mark - planes
- (void)addPlanesWithAnchor:(ARPlaneAnchor*)anchor forNode:(SCNNode*)node{
    // For the physics engine to work properly give the plane some height so we get interactions
    // between the plane and the gometry we add to the scene
    float planeHeight = 0.01;
    CGFloat width = anchor.extent.x;
    CGFloat length = anchor.extent.z;
    
    SCNBox *planeGeometry = [SCNBox boxWithWidth:width height:planeHeight length:length chamferRadius:0];
    //We only need top surface of box to display grid
    SCNMaterial *transparentMaterial = [SCNMaterial new];
    transparentMaterial.diffuse.contents = [UIColor clearColor];
    //We don't wanna transparent material interacts with lights
    transparentMaterial.lightingModelName = SCNLightingModelConstant;
    
    SCNMaterial *topMaterail = _gridMaterial ? : transparentMaterial;
    //update texture scale.
    //When plane grow larger, gird should cover it over and over. Otherwise, gird should be cliped to fit
    topMaterail.diffuse.contentsTransform = SCNMatrix4Scale(SCNMatrix4Identity, planeGeometry.width, planeGeometry.length, 1);
    
    planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, topMaterail, transparentMaterial];
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:planeGeometry];
    //Move plane down along Y axis to keep flatness
    SCNVector3 position = SCNVector3FromFloat3(anchor.center);
    position.y -= planeHeight/2;
    planeNode.position = position;
    planeNode.name = @"plane";
    planeNode.castsShadow = NO;
    [node addChildNode:planeNode];
    
    [_planes setObject:planeNode forKey:anchor.identifier];
}
- (void)updatePlanesForAnchor:(ARPlaneAnchor*)anchor{
    SCNNode *plane = _planes[anchor.identifier];
    if (!plane) {
        return;
    }
    SCNBox *planeGeometry = (SCNBox *)plane.geometry;
    planeGeometry.width = anchor.extent.x;
    planeGeometry.length = anchor.extent.z;
    
    SCNVector3 position = SCNVector3FromFloat3(anchor.center);
    position.y -= planeGeometry.height/2;
    plane.position = position;
    
    SCNMaterial *topMaterail = plane.geometry.materials[4];
    topMaterail.diffuse.contentsTransform = SCNMatrix4Scale(SCNMatrix4Identity, planeGeometry.width, planeGeometry.length, 1);
}
-(void)removePlaneForAnchor:(ARPlaneAnchor*)anchor{
    SCNNode *plane = _planes[anchor.identifier];
    [plane removeFromParentNode];
    [_planes removeObjectForKey:anchor.identifier];
}
#pragma mark - utils
- (void)postInfomation:(NSString*)info{
    static BOOL isShowInfo = NO;
    if (isShowInfo) {
        return;
    }
    isShowInfo = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:info preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:^{
                isShowInfo = NO;
            }];
        });
    }];
}
@end
