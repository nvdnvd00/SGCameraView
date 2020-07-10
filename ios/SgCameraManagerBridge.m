//
//  SgCameraManagerBridge.m
//  BVLinearGradient
//
//  Created by Trai Nguyen on 7/9/20.
//

#import "SgCameraManagerBridge.h"
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE(SgCameraManager, SgCameraManager, NSObject)


RCT_EXTERN_METHOD(remerge:(double)adjustment recordedUrl:(NSString *)recordedUrl mergeredUrl:(NSString *)mergeredUrl beat:(NSString *)beat adjustVolumeRecordingVideoIOS:(double)adjustVolumeRecordingVideoIOS adjustVolumeMusicVideoIOS:(double)adjustVolumeMusicVideoIOS callback:(RCTResponseSenderBlock)callback)

@end
