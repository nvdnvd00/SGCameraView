//
//  RecordingManager.swift
//  KaraokePlus
//
//  Created by Trai Nguyen on 5/23/20.
//  Copyright © 2020 Trai Nguyen. All rights reserved.
//

import Foundation

@objc(RecordingManager)
class RecordingManager: RCTViewManager {
    
  @objc var beat: String?
  @objc var lyric: [Any]?
  @objc var onRecordingEnd: RCTDirectEventBlock?
  @objc var delay: Double = 0.0
  @objc var adjustVolumeMusicVideoIOS: Double = 0.0
  @objc var adjustVolumeRecordingVideoIOS: Double = 0.0
    
  private var recordingView: RecordingView?
  
    override func view() -> UIView! {
      let recordingView = RecordingView()
      recordingView.beat = self.beat
      recordingView.lyric = self.lyric
      recordingView.onRecordingEnd = self.onRecordingEnd
      recordingView.delay = self.delay
      recordingView.adjustVolumeMusicVideoIOS = self.adjustVolumeMusicVideoIOS
      recordingView.adjustVolumeRecordingVideoIOS = self.adjustVolumeRecordingVideoIOS
      self.recordingView = recordingView
      return self.recordingView!
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
      return true
    }
    
    @objc func cancelRecord() {
        if let recordingView = self.recordingView {
            recordingView.cancelRecording()
        }
    }
    
    @objc func remerge(adjustment: Double,
                       recordedUrl: String,
                       beat: String,
                       adjustVolumeRecordingVideoIOS: Double,
                       adjustVolumeMusicVideoIOS: Double,
                       callback: @escaping RCTResponseSenderBlock) {
        if let recordingView = self.recordingView {
            recordingView.mergeVideoAndAudio(inputVideo: recordedUrl,
                                             beat: beat,
                                             adjustVolumeRecordingVideoIOS: adjustVolumeRecordingVideoIOS,
                                             adjustVolumeMusicVideoIOS: adjustVolumeMusicVideoIOS,
                                             delay: adjustment) { (url, error) in
                guard let remergeUrl = url else {
                    callback([NSNull(), NSNull()])
                    print(error?.localizedDescription ?? "Something went wrong when remerge video with adjustment \(adjustment)")
                    return
                }
                callback([NSNull(), remergeUrl.path])
            }
        }
    }
}
