//
//  MRecorder.swift
//  KaraokeSample
//
//  Created by Tue Nguyen on 9/7/20.
//  Copyright © 2020 Savvycom. All rights reserved.
//

import UIKit
import AVFoundation

protocol MovieRecorderDelegate: class {
    func movieRecorderDidFinishPreparing(recorder: MovieRecorder)
    func movieRecorder(recorder: MovieRecorder, didFailWithError error: Error?)
    func movieRecorderDidFinishRecording(recorder: MovieRecorder)
    func movieRecorder(_ recorder: MovieRecorder, didAppendAudio sampleBuffer: CMSampleBuffer)
}

enum MRecorderStatus: Int, Comparable {
    case idle = 0
    case preparingToRecord
    case recording
    case finishingRecordingPart1
    case finishingRecordingPart2
    case finished
    case failed
    
    static func < (lhs: MRecorderStatus, rhs: MRecorderStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

class MovieRecorder {
    private(set) var status: MRecorderStatus = .idle
    
    private(set) var outputURL: URL
    private var assetWriter: AVAssetWriter?
    
    private var hasStartedSession: Bool = false
    
    //Audio
    private var audioTrackSourceFormatDescription: CMFormatDescription?
    private var audioTrackSettings: [String: Any]?
    private var audioInput: AVAssetWriterInput?
    
    //Video
    private var videoTrackSourceFormatDescription: CMFormatDescription?
    private var videoTrackTransform: CGAffineTransform = .identity
    private var videoTrackSettings: [String: Any]?
    private var videoInput: AVAssetWriterInput?
    
    
    private let lockQueue = DispatchQueue(label: "com.apple.sample.movierecorder.lock", attributes: .concurrent)
    
    private let writingQueue = DispatchQueue(label: "com.apple.sample.movierecorder.writing")
    private(set) var delegateCallbackQueue: DispatchQueue
    private(set) weak var delegate: MovieRecorderDelegate?
    
    
    init(outputUrl: URL, delegate: MovieRecorderDelegate, callbackQueue: DispatchQueue) {
        self.outputURL = outputUrl
        self.delegate = delegate
        self.delegateCallbackQueue = callbackQueue
    }
    
    // Only one audio and video track each are allowed.
    func addVideoTrack(formatDescription: CMFormatDescription, transform: CGAffineTransform, settings: [String: Any]) { // see AVVideoSettings.h for settings keys/values
        guard status == .idle else {
            return
        }
        
        self.videoTrackSourceFormatDescription = formatDescription
        self.videoTrackTransform = transform
        self.videoTrackSettings = settings
    }
    
    func addAudioTrack(formatDescription: CMFormatDescription, settings: [String: Any]) { // see AVAudioSettings.h for settings keys/values
        guard status == .idle else {
            return
        }
        
        self.audioTrackSourceFormatDescription = formatDescription
        self.audioTrackSettings = settings
    }
    
    // Asynchronous, might take several hundred milliseconds.
    // When finished the delegate's recorderDidFinishPreparing: or recorder:didFailWithError: method will be called.
    func prepareToRecord() {
        var continueExecution = true
        self.performInLockQueue {
            if self.status != .idle { // Already prepared
                continueExecution = false
                return
            }
            self.transitionToStatus(newStatus: .preparingToRecord, error: nil)
        }
        
        guard continueExecution else {
            return
        }
        writingQueue.async {
            self.hasStartedSession = false
            try? FileManager.default.removeItem(at: self.outputURL)
            do {
                try self.assetWriter = AVAssetWriter(url: self.outputURL, fileType: .mov)
                var setupVideoWriterResult = true
                var setupAudioWriterResult = true
                //Video
                if let formatDescription = self.videoTrackSourceFormatDescription, let videoSettings = self.videoTrackSettings {
                    setupVideoWriterResult = self.setupAssetWriterVideoInputWithSourceFormatDescription(videoFormatDescription: formatDescription, transform: self.videoTrackTransform, settings: videoSettings)
                }
                //Audio
                if let audioDescription = self.audioTrackSourceFormatDescription, let audioSettings = self.audioTrackSettings {
                    setupAudioWriterResult = self.setupAssetWriterAudioInputWithSourceFormatDescription(audioFormatDescription: audioDescription, settings: audioSettings)
                }
                
                if setupAudioWriterResult && setupVideoWriterResult {
                    if let success = self.assetWriter?.startWriting(), !success, let error = self.assetWriter?.error {
                        throw error
                    }
                    self.performInLockQueue {
                        self.transitionToStatus(newStatus: .recording, error: nil)
                    }
                } else {
                    print("MovieRecorder Error when setup writer \(setupAudioWriterResult ? "video" : "audio")")
                }
            } catch {
                print("MovieRecorder Error: \(error)")
                self.performInLockQueue {
                    self.transitionToStatus(newStatus: .failed, error: error)
                }
            }
        }
    }
    
    func appendVideo(sampleBuffer: CMSampleBuffer) {
        self.append(sampleBuffer: sampleBuffer, mediaType: .video)
    }
    
    func appendAudio(sampleBuffer: CMSampleBuffer) {
        self.append(sampleBuffer: sampleBuffer, mediaType: .audio)
    }
    
    // Asynchronous, might take several hundred milliseconds.
    // When finished the delegate's recorderDidFinishRecording: or recorder:didFailWithError: method will be called.
    func finishRecording() {
        var shouldFinishRecording = false
        self.performInLockQueue {
            switch self.status {
            case .recording:
                shouldFinishRecording = true
            default:
                break
            }
            
            if shouldFinishRecording {
                self.transitionToStatus(newStatus: .finishingRecordingPart1, error: nil)
            }
        }
        
        guard shouldFinishRecording else { return }
        writingQueue.async {
            self.performInLockQueue {
                guard self.status == .finishingRecordingPart1 else { return }
                self.transitionToStatus(newStatus: .finishingRecordingPart2, error: nil)
            }
            
            self.assetWriter?.finishWriting(completionHandler: {
                self.performInLockQueue {
                    if let error = self.assetWriter?.error {
                        self.transitionToStatus(newStatus: .failed, error: error)
                    } else {
                        self.transitionToStatus(newStatus: .finished, error: nil)
                    }
                }
            })
        }
    }
    
    private func transitionToStatus(newStatus: MRecorderStatus, error: Error?) {
        guard newStatus != status else {
            return
        }
        
        var shouldNotifyDelegate = false
        
        if newStatus == .finished || newStatus == .failed {
            shouldNotifyDelegate = true
            self.writingQueue.async {
                self.teardownAssetWriterAndInputs()
                if newStatus == .failed {
                    try? FileManager.default.removeItem(at: self.outputURL)
                }
            }
            if let error = error {
                print("MovieRecorder Recorder Error: \(error)")
            }
        } else if newStatus == .recording {
            shouldNotifyDelegate = true
        }
        
        status = newStatus
        if shouldNotifyDelegate {
            delegateCallbackQueue.async {[weak self] in
                guard let self = self else { return }
                switch newStatus {
                case .recording:
                    self.delegate?.movieRecorderDidFinishPreparing(recorder: self)
                case .finished:
                    self.delegate?.movieRecorderDidFinishRecording(recorder: self)
                case .failed:
                    self.delegate?.movieRecorder(recorder: self, didFailWithError: error)
                default:
                    break
                }
            }
        }
    }
    
    private func setupAssetWriterVideoInputWithSourceFormatDescription(videoFormatDescription: CMFormatDescription, transform: CGAffineTransform, settings: [String: Any]) -> Bool{
        guard let assetWriter = self.assetWriter else { return false }
        
        if assetWriter.canApply(outputSettings: settings, forMediaType: .video) {
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings, sourceFormatHint: videoFormatDescription)
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = transform
            if (assetWriter.canAdd(videoInput)) {
                assetWriter.add(videoInput)
                self.videoInput = videoInput
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    private func setupAssetWriterAudioInputWithSourceFormatDescription(audioFormatDescription: CMFormatDescription, settings: [String: Any]) -> Bool {
        guard let assetWriter = self.assetWriter else { return false }
        
        if assetWriter.canApply(outputSettings: settings, forMediaType: .audio) {
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings, sourceFormatHint: audioFormatDescription)
            audioInput.expectsMediaDataInRealTime = true
            if (assetWriter.canAdd(audioInput)) {
                assetWriter.add(audioInput)
                self.audioInput = audioInput
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    private func teardownAssetWriterAndInputs() {
        self.assetWriter = nil
        self.videoInput = nil
        self.audioInput = nil
    }
    
    private func append(sampleBuffer: CMSampleBuffer, mediaType: AVMediaType) {
        var readyToAppend = true
        self.performInLockQueue {
            if self.status < .recording {
                readyToAppend = false
            }
        }
        guard readyToAppend else { return }
        
        writingQueue.async {
            self.performInLockQueue {
                if self.status > .finishingRecordingPart1 {
                    readyToAppend = false
                }
            }
            
            guard readyToAppend else { return }
            
            let bufferTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if !self.hasStartedSession && mediaType == .video {
                //Discard video frame util receive audio frame
                return
            }
            
            if !self.hasStartedSession {
                self.assetWriter?.startSession(atSourceTime: bufferTime)
                self.hasStartedSession = true
            }
            
            guard let input = mediaType == .video ? self.videoInput : self.audioInput else { return }
            
            if input.isReadyForMoreMediaData {
                if mediaType == .audio {
                    self.delegate?.movieRecorder(self, didAppendAudio: sampleBuffer)
                }
                
                let success = input.append(sampleBuffer)
                if !success {
                    let error = self.assetWriter?.error
                    self.performInLockQueue {
                        self.transitionToStatus(newStatus: .failed, error: error)
                    }
                    
                    if let error = error {
                        print("MovieRecorder error appendSampleBuffer \(error)")
                    }
                }
            } else {
                print("MovieRecorder \(mediaType) input not ready for more media data, dropping buffer")
            }
        }
    }
    
    private func performInLockQueue(block: () -> Void) {
        lockQueue.sync(flags: .barrier, execute: block)
    }
}
