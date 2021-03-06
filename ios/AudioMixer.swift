//
//  AudioMixer.swift
//  KaraokeSample
//
//  Created by Tue Nguyen on 9/4/20.
//  Copyright © 2020 Savvycom. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioMixerDelegate: class {
    func audioMixerMusicDidFinish(_ mixer: AudioMixer)
    func audioMixerDidReceive(sampleBuffer: CMSampleBuffer)
}

class AudioMixer {
    private(set) var backgroundMusicURL: URL
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var audioMixer: AVAudioMixerNode = AVAudioMixerNode()
    private var playerNodeForMixer: AVAudioPlayerNode = AVAudioPlayerNode()
    
    private(set) var isRuninng: Bool = false
    weak var delegate: AudioMixerDelegate?
    
    private var isPlayerReady = false
    
    init(bgMusic: URL) {
        self.backgroundMusicURL = bgMusic
    }
    
    func prepare() {
        audioEngine = AVAudioEngine()
        
        // Activate audio session
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options:[.mixWithOthers, .allowBluetoothA2DP, .defaultToSpeaker])
        try! AVAudioSession.sharedInstance().setActive(true)
        self.setInputGain(gain: 1.0)
        
        let mainMixer = audioEngine.mainMixerNode
        let mixerOutputFormat: AVAudioFormat = mainMixer.outputFormat(forBus: 0)
        
        let playerNodeForMixer = AVAudioPlayerNode()
        audioEngine.attach(playerNodeForMixer)
        
        let audioMixer = AVAudioMixerNode()
        audioEngine.attach(audioMixer)
        
        let muteMixer = AVAudioMixerNode()
        muteMixer.outputVolume = 0
        muteMixer.volume = 0
        audioEngine.attach(muteMixer)
        
        let playerNodeForOutput = AVAudioPlayerNode()
        audioEngine.attach(playerNodeForOutput)
        
        let micMixer = AVAudioMixerNode()
        audioEngine.attach(micMixer)
        
        let mic = audioEngine.inputNode
        audioEngine.connect(mic, to: micMixer, format: mic.inputFormat(forBus: 0))
        audioEngine.connect(micMixer, to: audioMixer, format: mixerOutputFormat)
        audioEngine.connect(audioMixer, to: muteMixer, format: mixerOutputFormat)
        audioEngine.connect(muteMixer, to: mainMixer, format: mixerOutputFormat)
        
        // background audio
        let connectionPoints = [
            AVAudioConnectionPoint(node: audioMixer, bus: audioMixer.nextAvailableInputBus),
            AVAudioConnectionPoint(node: mainMixer, bus: mainMixer.nextAvailableInputBus)
        ]
        let playerNodeFormat = playerNodeForMixer.outputFormat(forBus: 0)
        audioEngine.connect(playerNodeForMixer, to: connectionPoints, fromBus: 0, format: playerNodeFormat)
        
        self.audioMixer = audioMixer
        self.playerNodeForMixer = playerNodeForMixer
        
        //Tap Audio + Mic out
        let bufferSize: UInt32 = 1024
        let tapFormat = audioMixer.outputFormat(forBus: 0)
        audioMixer.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) {[weak self] (buffer, when) in
            guard let self = self, self.isRuninng, self.playerNodeForMixer.isPlaying else { return }
            if let delegate = self.delegate, let sampleBuffer = buffer.createAudioSampleBufferWithATS(ATS: when) {
                delegate.audioMixerDidReceive(sampleBuffer: sampleBuffer)
            }
        }
        
        //Tap Audio out
        /*
        let audioWriter = try! AVAudioFile(forWriting: try! ViewController.getOutputUrl(name: "audio_out.aac"), settings: self.audioSettings)
        let tapPlayerFormat = playerNodeForMixer.outputFormat(forBus: 0)
        playerNodeForMixer.installTap(onBus: 0, bufferSize: bufferSize, format: tapPlayerFormat) {[weak self] (buffer, when) in
            if let self = self, self.playerNodeForMixer.isPlaying {
                try? audioWriter.write(from: buffer)
            }
        }*/
        
        self.audioEngine.reset()
        self.audioEngine.prepare()
    }
    
    func start() {
        if isRuninng {
            return
        }
        isPlayerReady = false
        isRuninng = true
        
        do {
            try self.audioEngine.start()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {//Make sure engine start before player start to avoid audio cut off
                
            
//            }
            // background audio
            if let backgroundAudio = try? AVAudioFile(forReading: backgroundMusicURL) {
                playerNodeForMixer.play()
                playerNodeForMixer.scheduleFile(backgroundAudio, at: nil) { [weak self] in
                    guard let self = self else { return }
                    if let delegate = self.delegate {
                        DispatchQueue.main.async {
                            delegate.audioMixerMusicDidFinish(self)
                        }
                    }
                }
            }
        } catch {
            print("audioEngine.start error \(error)")
        }
    }
    
    func stop() {
        self.audioEngine.stop()
        self.audioMixer.removeTap(onBus: 0)
        self.playerNodeForMixer.removeTap(onBus: 0)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        isRuninng = false
    }
    
    var audioFormatDescrition: CMAudioFormatDescription? {
        let mainMixer = self.audioMixer
        let mixerOutputFormat = mainMixer.outputFormat(forBus: 0)
        
        var mAudioFormatDescription: CMFormatDescription? = nil
        CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: mixerOutputFormat.streamDescription, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &mAudioFormatDescription)
        return mAudioFormatDescription
    }
    
    var audioSettings: [String: Any] {
        let mainMixer = self.audioMixer
        let mixerOutputFormat = mainMixer.outputFormat(forBus: 0)
        let channelLayout = mixerOutputFormat.channelLayout
        
        let channelLayoutData = Data(bytes: channelLayout!.layout, count: MemoryLayout.offset(of: \AudioChannelLayout.mChannelDescriptions)!)
        
        let compressionAudioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: 320000,
            AVSampleRateKey: mixerOutputFormat.sampleRate,
            AVChannelLayoutKey: channelLayoutData,
            AVNumberOfChannelsKey: mixerOutputFormat.channelCount
        ]
        return compressionAudioSettings
    }
    
    func setInputGain(gain: Float) {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.isInputGainSettable {
            do {
                try audioSession.setInputGain(gain)
            } catch {
                print("set input gain \(error)")
            }
        } else {
            print("Cannot set input gain")
        }
    }
}

extension AVAudioPCMBuffer {
    func createAudioSampleBufferWithATS(ATS: AVAudioTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer? = nil
        var format: CMAudioFormatDescription? = nil
        let asbd = self.format.streamDescription
        var error = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &format)
        if error != noErr {
            return nil
        }
        let PTS = CMTimeMake(value: Int64(AVAudioTime.seconds(forHostTime: ATS.hostTime) * ATS.sampleRate), timescale: Int32(ATS.sampleRate))
        
        let bufferListPointer = UnsafeMutableAudioBufferListPointer(self.mutableAudioBufferList)
        let count = CMItemCount(bufferListPointer[1].mDataByteSize / asbd.pointee.mBytesPerFrame)
//        var dataBuffer: CMBlockBuffer? = nil
//        var blockSize = Int(asbd.pointee.mBytesPerFrame * asbd.pointee.mChannelsPerFrame)
//        error = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: blockSize, blockAllocator: nil, customBlockSource: nil, offsetToData: 0, dataLength: blockSize, flags: 0, blockBufferOut: &dataBuffer)
        error = CMAudioSampleBufferCreateWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: nil, dataReady: false, makeDataReadyCallback: nil, refcon: nil, formatDescription: format!, sampleCount: count, presentationTimeStamp: PTS, packetDescriptions: nil, sampleBufferOut: &sampleBuffer)
//        error = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault, dataBuffer: dataBuffer!, formatDescription: format!, sampleCount: count, presentationTimeStamp: PTS, packetDescriptions: nil, sampleBufferOut: &sampleBuffer)
        
        if error != noErr {
            return nil
        }
        
        error = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!, blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, bufferList: self.audioBufferList)
        
        if error != noErr {
            return nil
        }
        
        return sampleBuffer
    }
}
