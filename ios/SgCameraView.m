#import "SgCameraView.h"
#import <React/RCTViewManager.h>
#import <Foundation/Foundation.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTComponent.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTDevLoadingView.h>
#import <React/RCTConvert.h>
//
//  RecordingManagerBridge.m
//  KaraokePlus
//
//  Created by Trai Nguyen on 5/23/20.
//  Copyright © 2020 Trai Nguyen. All rights reserved.
//

@interface RCT_EXTERN_REMAP_MODULE(SgCameraView, RecordingManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(beat, NSString)
RCT_EXPORT_VIEW_PROPERTY(lyric, NSString)
RCT_EXPORT_VIEW_PROPERTY(onRNCRecordingEnd, RCTBubblingEventBlock)
@end
