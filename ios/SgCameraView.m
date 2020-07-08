#import "SgCameraView.h"
#import <React/RCTViewManager.h>
#import <Foundation/Foundation.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTComponent.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTDevLoadingView.h>
#import <React/RCTConvert.h>
#import <React/UIView+React.h>
#import <React/RCTUIManager.h>
#import <React/RCTLog.h>

@interface RCT_EXTERN_REMAP_MODULE(SgCameraView, RecordingManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(beat, NSString)
RCT_EXPORT_VIEW_PROPERTY(lyric, NSArray)
RCT_EXPORT_VIEW_PROPERTY(onRecordingEnd, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(delay, double)
RCT_EXPORT_VIEW_PROPERTY(adjustVolumeMusicVideoIOS, double)
RCT_EXPORT_VIEW_PROPERTY(adjustVolumeRecordingVideoIOS, double)
RCT_EXTERN_METHOD(cancelRecord)
RCT_EXTERN_METHOD(remerge:(double)adjustment
                  recordedUrl:(NSString)recordedUrl
                  beat:(NSString)beat
                  adjustVolumeRecordingVideoIOS:(double)adjustVolumeRecordingVideoIOS
                  adjustVolumeMusicVideoIOS:(double)adjustVolumeMusicVideoIOS
                  callback:(RCTResponseSenderBlock)callback)
@end
