//
//  DFBlunoManager.h
//
//  Created by Seifer on 13-12-1.
//  Copyright (c) 2013年 DFRobot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEUtility.h"
#import "BLEDevice.h"
#import "DFBlunoDevice.h"

@protocol DFBlunoDelegate <NSObject>
@required

-(void)bleDidUpdateState:(BOOL)bleSupported;
-(void)didDiscoverDevice:(DFBlunoDevice*)dev;
-(void)readyToCommunicate:(DFBlunoDevice*)dev;
-(void)didDisconnectDevice:(DFBlunoDevice*)dev;
-(void)didWriteData:(DFBlunoDevice*)dev;
-(void)didReceiveData:(NSData*)data Device:(DFBlunoDevice*)dev;

@end

@interface DFBlunoManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,weak) id<DFBlunoDelegate> delegate;

+ (id)sharedInstance;
- (void)scan;
- (void)stop;
- (void)clear;
- (void)connectToDevice:(DFBlunoDevice*)dev;
- (void)disconnectToDevice:(DFBlunoDevice*)dev;
- (void)writeDataToDevice:(NSData*)data Device:(DFBlunoDevice*)dev;

@end
