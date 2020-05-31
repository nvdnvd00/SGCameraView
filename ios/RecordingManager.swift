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
    
  private var recordingView: RecordingView?
  
    override func view() -> UIView! {
      let recordingView = RecordingView()
      recordingView.beat = self.beat
      recordingView.lyric = self.lyric
      recordingView.onRecordingEnd = self.onRecordingEnd
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
