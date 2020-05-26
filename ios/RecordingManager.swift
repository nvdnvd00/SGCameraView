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
    @objc var lyric: String?
    @objc var onRecordingEnd: RCTDirectEventBlock?
  
    override func view() -> UIView! {
      let recordingView = RecordingView()
      recordingView.beat = self.beat
      recordingView.lyric = self.lyric
      recordingView.onRecordingEnd = self.onRecordingEnd
      return recordingView
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
      return true
    }
}

