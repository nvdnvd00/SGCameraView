//
//  RecordingManager.swift
//  KaraokePlus
//
//  Created by Trai Nguyen on 5/23/20.
//  Copyright © 2020 Trai Nguyen. All rights reserved.
//

import Foundation
import AudioKit

@objc(RecordingManager)
class RecordingManager: RCTViewManager {
    
  @objc var albumPreview: String?
  @objc var beat: String?
  @objc var beatDetail: Dictionary<String, Any>?
  @objc var lyric: [Any]?
  @objc var onRecordingEnd: RCTDirectEventBlock?
  @objc var delay: Double = 0.0
  @objc var adjustVolumeMusicVideoIOS: Double = 0.0
  @objc var adjustVolumeRecordingVideoIOS: Double = 0.0
    
  private var recordingView: RecordingView?
  
    override func view() -> UIView! {
      AKManager.engine.reset()
      let recordingView = RecordingView()
      recordingView.albumPreview = self.albumPreview
      recordingView.beat = self.beat
      recordingView.beatDetail = self.beatDetail
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
}
