//
//  SgCameraManagerBridge.m
//  BVLinearGradient
//
//  Created by Trai Nguyen on 7/9/20.
//

#import <Foundation/Foundation.h>

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(SgCameraManager, NSObject)

RCT_EXTERN_METHOD()

RCT_EXTERN_METHOD(remerge:(double)adjustment recordedUrl:(NSString *)recordedUrl mergeredUrl:(NSString *)mergeredUrl beat:(NSString *)beat adjustVolumeRecordingVideoIOS:(double)adjustVolumeRecordingVideoIOS adjustVolumeMusicVideoIOS:(double)adjustVolumeMusicVideoIOS callback:(RCTResponseSenderBlock)callback)

@end
