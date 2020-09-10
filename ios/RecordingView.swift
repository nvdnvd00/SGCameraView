//
//  RecordingView.swift
//  MyRNApp
//
//  Created by Trai Nguyen on 5/25/20.
//

import UIKit
import AVKit
import AudioKit
import Kingfisher

class RecordingView: UIView {
  let RECORD_BUTTON_HEIGHT: CGFloat = 60
  private var videoFileOutput: AVCaptureMovieFileOutput?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private var player: AVPlayer?
  private var loadingView: UIView?
  private var btnRecord = UIButton(type: .custom)
  private var vwLyrics = UIView(frame: .zero)
  private var txvLyrics = UITextView(frame: .zero)
  private var imvAlbumPreview = UIImageView(frame: .zero)
  
  @objc var albumPreview: String?
  @objc var beat: String?
  @objc var beatDetail: Dictionary<String, Any>?
  @objc var lyric: [Any]?
  @objc var onRecordingEnd: RCTDirectEventBlock?
  @objc var lyricsNormalColor: UIColor = .black
  @objc var lyricsHighlightColor: UIColor = .white
  @objc var delay: Double = 0.0
  @objc var adjustVolumeMusicVideoIOS: Double = 0.0
  @objc var adjustVolumeRecordingVideoIOS: Double = 0.0
  
  private var arrLyricsModel: [Lyrics] = []
  private var timeObserverToken: Any?
  private var isUserScroll: Bool = false
  private var isCancelRecording: Bool = false
  private let TIME_CONTROL_STATUS_KEY = "timeControlStatus"
  private var isAddObserver: Bool = false
  private var latencyTime: Double = 0.0

  private var urlAfterRecorded: URL?
    
  private var mic : AKMicrophone?
  private var beatPlayer: AKPlayer?
  private var micMixer: AKMixer!
  private var recorder: AKNodeRecorder!
  private var recordPlayer: AKPlayer!
  private var tape: AKAudioFile!
  private var mixerBooster: AKBooster!
  private var mainMixer: AKMixer!
  private var periodicFunc: AKPeriodicFunction?
    
  override func draw(_ rect: CGRect) {
      updateLayout()
  }
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
  override init(frame: CGRect) {
     super.init(frame: frame)
     setupView()
   }
    
    override func reactSetFrame(_ frame: CGRect) {
        super.reactSetFrame(frame)
        self.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        updateLayout()
    }
  
   required init?(coder aDecoder: NSCoder) {
     super.init(coder: aDecoder)
     setupView()
   }
  
  private func setupView()  {
    self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    setupRecordButton()
    if let beat = self.beat, let _ = URL(string: beat) {
        self.setupAudioKitRecorder()
    }
    
//    setupAudioSession()
    setupLyricsView()
  }
    
    fileprivate func updateLayout() {
        if self.btnRecord.isHidden {
            updateRecordButtonPosition()
        }
        if self.loadingView == nil {
          setupLoadingView()
        }
        if self.vwLyrics.frame == .zero {
            self.parseLyrics()
            self.updateLyricsViewPosition()
            self.updateHighlightLyrics(time: 0.0)
        }
//        if self.cameraPreviewLayer == nil {
//          self.showCameraPreview()
//          self.bringSubview(toFront:self.btnRecord)
//        }
        if self.imvAlbumPreview.frame == .zero {
            self.showAlbumPreview()
            self.bringSubview(toFront:self.btnRecord)
        }
    }
    
  fileprivate func updateRecordButtonPosition() {
    let xPosition: CGFloat = self.frame.size.width/2 - self.RECORD_BUTTON_HEIGHT/2
    let yPosition: CGFloat = self.frame.size.height - self.RECORD_BUTTON_HEIGHT - 10
    if self.btnRecord.isHidden {
      self.btnRecord.isHidden = false
    }
    self.btnRecord.frame = CGRect(x: xPosition, y: yPosition, width: self.RECORD_BUTTON_HEIGHT, height: self.RECORD_BUTTON_HEIGHT)
  }
  
  func startRecording() {
    DispatchQueue.main.async {
        self.loadingView?.isHidden = true
        self.bringSubview(toFront:self.btnRecord)
        self.btnRecord.isUserInteractionEnabled = true
        self.startRecordByAudioKit()
//      guard let beat = self.beat else {
//          print(String(describing: Self.self) ,#function, "ERROR: You must set beat url")
//          return
//      }
//      self.playAudio(urlString: beat)
    }
  }
  
  func stopRecording() {
    DispatchQueue.main.async {
        self.endRecordByAudioKit()
//      if let videoFileOutput = self.videoFileOutput, videoFileOutput.isRecording {
//        videoFileOutput.stopRecording()
//      }
//      if let player = self.player {
//          player.pause()
//          self.removePlayerObserver()
//      }
    }
  }
    
    @objc func cancelRecording() {
        print(String(describing: Self.self) ,#function)
        isCancelRecording = true
        if let output = self.videoFileOutput, output.isRecording {
            output.stopRecording()
        }
        if let player = self.player, player.rate > 0 {
            player.pause()
            self.removePlayerObserver()
        }
        
        if let beatPlayer = self.beatPlayer, beatPlayer.isPlaying {
            self.mixerBooster.gain = 0
            self.beatPlayer?.stop()
            self.periodicFunc?.stop()
            self.recorder.stop()
        }
    }
    
    @objc func endPlayVideo() {
        if self.btnRecord.isSelected {
            print("____endPlayVideo")
            stopRecording()
            self.btnRecord.isSelected = false
        }
    }
    
  fileprivate func realStartRecording() {
      loadingView?.isHidden = true
    self.bringSubview(toFront:self.btnRecord)
    self.btnRecord.isUserInteractionEnabled = true
      do {
          let initialOutputURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("output").appendingPathExtension("mov")
          videoFileOutput?.startRecording(to: initialOutputURL, recordingDelegate: self)
      } catch {
          print(error)
      }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      if let player =  object as? AVPlayer, keyPath == TIME_CONTROL_STATUS_KEY {
          if player.timeControlStatus == .playing {
              if let videoFileOutput = self.videoFileOutput, !videoFileOutput.isRecording {
                  player.pause()
                  realStartRecording()
                  return
              }
              print(String(describing: Self.self) ,#function, "2.is playing audio: \(Date().timeIntervalSince1970 * 1000)")
            let latency = Date().timeIntervalSince1970 * 1000
            self.latencyTime = latency - self.latencyTime
            print(String(describing: Self.self) ,#function, "REAL_LATENCY: \(self.latencyTime.rounded())")
          }
      }
  }
    
    private func removePlayerObserver() {
        if !self.isAddObserver { return }
        if let player = self.player {
            player.removeObserver(self, forKeyPath: TIME_CONTROL_STATUS_KEY)
        }
        removePeriodicTimeObserver()
        NotificationCenter.default.removeObserver(self)
        self.isAddObserver = false
    }
    
    deinit {
        removePeriodicTimeObserver()
        
        print(String(describing: Self.self) ,#function, "TN_TEST")
        videoFileOutput = nil
        
        player = nil
        
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil
        
        imvAlbumPreview.frame = .zero
        imvAlbumPreview.removeFromSuperview()
        
        loadingView?.removeFromSuperview()
        loadingView = nil
        
        self.txvLyrics.removeFromSuperview()
        self.vwLyrics.removeFromSuperview()
        
//        self.micBooster.gain = 0
        self.beatPlayer?.stop()
        self.periodicFunc?.stop()
//        self.recorder.stop()
        
        removePlayerObserver()
    }
}

//MARK: - Setup
extension RecordingView {
  fileprivate func setupRecordButton() {
    self.btnRecord.frame = CGRect(x: 12, y: 12, width: RECORD_BUTTON_HEIGHT, height: RECORD_BUTTON_HEIGHT)
    self.btnRecord.backgroundColor = UIColor.clear
    self.btnRecord.setImage(UIImage(named:"ic_play"), for: .normal)
    self.btnRecord.setImage(UIImage(named:"ic_pause"), for: .selected)
    self.btnRecord.layer.masksToBounds = true
    self.btnRecord.layer.cornerRadius = RECORD_BUTTON_HEIGHT/2
    self.addSubview(btnRecord)
    self.btnRecord.addTarget(self, action: #selector(ontapRecodingButton(sender:)), for: .touchUpInside)
    self.btnRecord.isHidden = true
  }
  
  @objc func ontapRecodingButton(sender: UIButton) {
    if sender.isSelected {
      stopRecording()
    }
    else {
        if let beat = self.beat, let _ = URL(string: beat) {
            self.setupAudioKitRecorder()
        }
        setupCountdownTimer()
        sender.isUserInteractionEnabled = false
    }
    sender.isSelected = !sender.isSelected
  }
  
    fileprivate func setupLoadingView() {
        self.loadingView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        self.loadingView?.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        self.addSubview(self.loadingView!)
        
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        self.loadingView?.addSubview(indicator)
        indicator.center = self.center
        indicator.startAnimating()
        
        self.loadingView?.isHidden = true
    }
    
    fileprivate func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, mode: AVAudioSessionModeVideoRecording, options: AVAudioSession.CategoryOptions.mixWithOthers)
        } catch {
            print(String(describing: Self.self) ,#function, "Can't Set Audio Session Category: \(error)")
        }
        
        // Start Session
        do {
            try audioSession.setActive(true)
        } catch {
            print(String(describing: Self.self) ,#function, "Can't Start Audio Session: \(error)")
        }
    }
    
    fileprivate func setupLyricsView() {
        self.txvLyrics.textColor = self.lyricsNormalColor
        self.txvLyrics.backgroundColor = .clear
        self.txvLyrics.textAlignment = .center
        self.txvLyrics.isEditable = false
        self.txvLyrics.layer.masksToBounds = true
        self.txvLyrics.delegate = self
        self.vwLyrics.addSubview(self.txvLyrics)
        
        self.addSubview(self.vwLyrics)
    }
    
    fileprivate func updateLyricsViewPosition() {
        let paddingTop: CGFloat = 55
        let paddingBottom: CGFloat = paddingTop + 5
        self.vwLyrics.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height * 0.25 + paddingTop)
        
        self.txvLyrics.frame = CGRect(x: 10, y: paddingTop, width: self.vwLyrics.bounds.size.width - 20, height: self.vwLyrics.bounds.size.height - paddingBottom)
        self.txvLyrics.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        
        let gradient = CAGradientLayer()
        let colorTop = UIColor(red: 255.0 / 255.0, green: 168.0 / 255.0, blue: 31.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 241.0 / 255.0, green: 190.0 / 255.0, blue: 65.0 / 255.0, alpha: 1.0).cgColor
        gradient.colors = [colorTop, colorBottom]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0.0, 0.75]
        gradient.frame = self.vwLyrics.frame
        self.vwLyrics.layer.insertSublayer(gradient, at: 0)
    }
    
    fileprivate func parseLyrics() {
        let decoder = JSONDecoder()
        if let lyricsDict = self.lyric as? [[String: Any]] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject:lyricsDict, options:[])
                self.arrLyricsModel = try decoder.decode([Lyrics].self, from: jsonData)
            } catch {
                print("JSON serialization failed:  \(error)")
            }
        }
    }
    
    fileprivate func setHiddenLoadingView(status: Bool) {
        DispatchQueue.main.async {
            if let loadingView = self.loadingView {
                self.bringSubview(toFront: loadingView)
                loadingView.isHidden = status
            }
        }
    }
    
    fileprivate func setupCountdownTimer() {
        DispatchQueue.main.async {
            let viewMask = UIView(frame: UIScreen.main.bounds)
            viewMask.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            self.addSubview(viewMask)
            
            let width: CGFloat = 100
            let height: CGFloat = 100
            let frame = CGRect(x: 0, y: 0, width: width, height: height)
            let countdownTimer = SRCountdownTimer(frame: frame)
            countdownTimer.labelFont = UIFont(name: "HelveticaNeue-Light", size: 50.0)
            countdownTimer.labelTextColor = UIColor.red
            countdownTimer.timerFinishingText = "0"
            countdownTimer.lineWidth = 4
            countdownTimer.delegate = self
            viewMask.addSubview(countdownTimer)
            countdownTimer.center = viewMask.center
            
            countdownTimer.start(beginingValue: 3, interval: 1)
            UIApplication.shared.keyWindow?.isUserInteractionEnabled = false
        }
    }
}
//MARK: - AudioKit
extension RecordingView {
    private func setupAudioKitRecorder() {
        do{
            try AudioKit.stop()
        }
        catch{
            print ("AudioKit stop error")
        }
        
        // Clean tempFiles !
        AKAudioFile.cleanTempDirectory()

        // Session settings
        AKSettings.bufferLength = .medium

        do {
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }

        AKSettings.defaultToSpeaker = true
        self.mic = AKMicrophone()
        // Patching
        var initMicGain: Double = 1
        if AKSettings.headPhonesPlugged {
            initMicGain = 3
        }
        if let beat = self.beat, let url = URL(string: beat) {
            let beatFile = try! AKAudioFile(forReading: url)
            self.beatPlayer = AKPlayer(audioFile: beatFile)
            self.beatPlayer?.volume = 0.8
            self.beatPlayer?.completionHandler = {
                self.stopRecording()
                self.btnRecord.isSelected = !self.btnRecord.isSelected
            }
            let micBooster = AKBooster(mic, gain: initMicGain)
            micMixer = AKMixer(micBooster, self.beatPlayer!)
        }
        else {
            print("Cannot load beat")
            let micBooster = AKBooster(mic, gain: initMicGain)
            micMixer = AKMixer(micBooster)
        }
        
        mixerBooster = AKBooster(micMixer)
        // Will set the level of microphone monitoring
        mixerBooster.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        if let file = recorder.audioFile {
//            file.maxLevel = 6.0
            recordPlayer = AKPlayer(audioFile: file)
        }

        mainMixer = AKMixer(mixerBooster)
        
        self.periodicFunc = AKPeriodicFunction(every: 0.25) {
            let time = self.beatPlayer?.currentTime ?? 0.0
            print("Beat time: \(time)")
            self.updateHighlightLyrics(time: time)
        }
        
        AudioKit.output = mainMixer
        do {
            self.periodicFunc?.start()
            if let periodic = self.periodicFunc {
                try AudioKit.start(withPeriodicFunctions: periodic)
            }
            else {
                try AudioKit.start()
            }
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    fileprivate func startRecordByAudioKit() {
        mixerBooster.gain = 1
        do {
            self.beatPlayer?.play()
            try recorder.record()
        } catch { AKLog("Errored recording.") }
    }
    
    fileprivate func endRecordByAudioKit() {
        mixerBooster.gain = 0
        tape = recorder.audioFile!
        recordPlayer.load(audioFile: tape)

        if let _ = recordPlayer.audioFile?.duration {
            self.periodicFunc?.stop()
            self.beatPlayer?.stop()
            recorder.stop()
            tape.exportAsynchronously(name: "TempTestFile.m4a",
                                      baseDir: .documents,
                                      exportFormat: .m4a) { audioFile , exportError in
                if let newAudioFile = audioFile {
                    if let completion = self.onRecordingEnd {
                        completion(["data":["recordedUrl": newAudioFile.url.path, "mergedUrl": newAudioFile.url.path, "latencyTime": 0.0, "type": "1"]])
                    }
                    else {
                        print("onRecordingEnd nil")
                    }
                }
                else if let error = exportError {
                    AKLog("Export Failed \(error)")
                }
            }
        }
    }
}


//MARK: - SRCountdownTimerDelegate
extension RecordingView: SRCountdownTimerDelegate {
    func timerDidEnd(sender: SRCountdownTimer, elapsedTime: TimeInterval) {
        if let viewMask = sender.superview {
            sender.removeFromSuperview()
            viewMask.removeFromSuperview()
        }
        self.startRecording()
        UIApplication.shared.keyWindow?.isUserInteractionEnabled = true
    }
}

//MARK: - Update highlight lyrics
extension RecordingView {
    fileprivate func updateHighlightLyrics(time: Double = 0.0) {
        var highlightLyricsString = ""
        var normalLyricsString = ""
        
        highlightLyricsString.append(self.getHighlightTextFullSentence(array: self.arrLyricsModel, time: time))
        
        let (highlightHalf, normalHalf) = self.getStatusTextHalfSentence(array: self.arrLyricsModel, time: time)
        if highlightLyricsString.count > 0 {
            highlightLyricsString.append("\n")
        }
        highlightLyricsString.append(highlightHalf)
        if highlightHalf.count > 0 && normalHalf.count > 0 {
            highlightLyricsString.append(" ")
        }
        else if highlightHalf.count > 0 || normalHalf.count > 0{
            highlightLyricsString.append("\n")
        }
        normalLyricsString.append(normalHalf)
        let newNormalTextFullSentence = self.getNormalTextFullSentence(array: self.arrLyricsModel, time: time)
        if newNormalTextFullSentence.count > 0 {
            if normalLyricsString.count > 0  {
                normalLyricsString.append("\n")
            }
            normalLyricsString.append(newNormalTextFullSentence)
        }
        
        var finalString = highlightLyricsString + normalLyricsString
        finalString = finalString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        //Scroll
        /*
        if self.isUserScroll == false && finalString.count > 0 {
            let percentHilightText: Double = Double(highlightLyricsString.count) / Double(finalString.count)
            let highlightPosition = CGFloat(percentHilightText) * self.txvLyrics.contentSize.height
            var yPosition = (highlightPosition - (self.txvLyrics.frame.size.height/2)) > 0 ? (highlightPosition - (self.txvLyrics.frame.size.height/2)) : 0
            let height = self.txvLyrics.frame.size.height
            if (yPosition + height) >= self.txvLyrics.contentSize.height {
                yPosition = self.txvLyrics.contentSize.height - height
            }
            let visibleFrame = CGRect(x: 0, y: yPosition, width: self.txvLyrics.frame.size.width, height: height)
            self.txvLyrics.scrollRectToVisible(visibleFrame, animated: true)
        }
         */
        if self.isUserScroll == false && finalString.count > 0 {
            if let endPos = txvLyrics.position(from: txvLyrics.beginningOfDocument, offset: highlightLyricsString.count), let textRange = txvLyrics.textRange(from: txvLyrics.beginningOfDocument, to: endPos) {
                let lyricsHeight = self.txvLyrics.frame.size.height
                
//                let rect = txvLyrics.firstRect(for: textRange)
                let rect = txvLyrics.caretRect(for: textRange.end)
                if rect.origin.y > lyricsHeight / 2 {
                    var yPosition = rect.origin.y - lyricsHeight / 2
                    if (yPosition + lyricsHeight) >= self.txvLyrics.contentSize.height {
                        yPosition = self.txvLyrics.contentSize.height - lyricsHeight
                    }
                    let visibleFrame = CGRect(x: 0, y: yPosition, width: self.txvLyrics.frame.size.width, height: lyricsHeight)
                    self.txvLyrics.scrollRectToVisible(visibleFrame, animated: true)
                }
            }
        }
        
        let finalAttributeString = NSMutableAttributedString(string: finalString)
        if highlightLyricsString.count == 0 {
            finalAttributeString.addAttributes([.foregroundColor : self.lyricsNormalColor], range: NSRange(location: 0, length: finalString.count))
        }
        else if normalLyricsString.count == 0 {
            finalAttributeString.addAttributes([.foregroundColor : self.lyricsHighlightColor], range: NSRange(location: 0, length: finalString.count))
        }
        else {
            finalAttributeString.addAttributes([.foregroundColor : self.lyricsHighlightColor], range: NSRange(location: 0, length: highlightLyricsString.count))
            finalAttributeString.addAttributes([.foregroundColor : self.lyricsNormalColor], range: NSRange(location: highlightLyricsString.count, length: normalLyricsString.count))
        }
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        finalAttributeString.addAttributes([.font : font, .paragraphStyle: paragraph], range: NSRange(location: 0, length: finalString.count))
        self.txvLyrics.attributedText = finalAttributeString
    }
    
    fileprivate func getHighlightTextFullSentence(array: [Lyrics], time: Double) -> String{
        var highlightLyricsString = ""
        let highlightTextFullSentence = array.filter({ ($0.end ?? 0) <= time })
        for lyrics in highlightTextFullSentence {
            if let content = lyrics.content {
                if highlightLyricsString.count > 0 {
                    highlightLyricsString.append("\n")
                }
                highlightLyricsString.append(self.removeTimeInString(string: content))
            }
        }
        return highlightLyricsString
    }
    
    fileprivate func getStatusTextHalfSentence(array: [Lyrics], time: Double) -> (highlight: String, normal: String) {
        var highlightLyricsString = ""
        var normalLyricsString = ""
        let highlightTextHalf = array.filter({ ($0.start ?? 0) <= time && ($0.end ?? 0) > time})
        for lyrics in highlightTextHalf {
            if let arrChildLyrics = lyrics.data {
                for childLyrics in arrChildLyrics {
                    if let content = childLyrics.content, let start = childLyrics.start {
                        if start <= time {
                            if highlightLyricsString.count > 0 {
                                highlightLyricsString.append(" ")
                            }
                            highlightLyricsString.append(content)
                        }
                        else {
                            if normalLyricsString.count > 0 {
                                normalLyricsString.append(" ")
                            }
                            normalLyricsString.append(content)
                        }
                    }
                }
            }
        }
        return (highlightLyricsString, normalLyricsString)
    }
    
    fileprivate func getNormalTextFullSentence(array: [Lyrics], time: Double) -> String {
        var normalLyricsString = ""
        let normalTextFullSentence = self.arrLyricsModel.filter({ ($0.start ?? 0) > time })
        for lyrics in normalTextFullSentence {
            if let content = lyrics.content {
                if normalLyricsString.count > 0 {
                    normalLyricsString.append("\n")
                }
                normalLyricsString.append(self.removeTimeInString(string: content))
            }
        }
        return normalLyricsString
    }
    
    fileprivate func removeTimeInString(string: String) -> String {
        let regex = try! NSRegularExpression(pattern: "<(.*?)>", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, string.count)
        var resultString = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        resultString = resultString.components(separatedBy: .whitespacesAndNewlines).filter({!$0.isEmpty}).joined(separator: " ")
        return resultString
    }
}
//MARK: - Record
extension RecordingView {
    fileprivate func playAudio(urlString: String) {
        let videoURL = URL(string: urlString)
        let playerItem: AVPlayerItem = AVPlayerItem(url: videoURL!)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer
        self.player?.play()
        let playerLayer = AVPlayerLayer(player: self.player)
        if let window = UIApplication.shared.keyWindow {
            playerLayer.frame = window.bounds
            window.layer.addSublayer(playerLayer)
        }
        else {
            print(String(describing: Self.self) ,#function, "ERROR: Cannot load WINDOW view")
        }
        self.player?.addObserver(self, forKeyPath: TIME_CONTROL_STATUS_KEY, options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endPlayVideo), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        self.addPeriodicTimeObserver()
        self.isAddObserver = true
    }
    
    fileprivate func showCameraPreview() {
//        DispatchQueue.main.async {
            let captureSession = AVCaptureSession()
            
            // Preset For 720p
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else {
            print(String(describing: Self.self) ,#function, "Current Device does not support camera!")
            return
        }
            // Video Input
            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: camera)
                
                // Add Video Input
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    print(String(describing: Self.self) ,#function, "ERROR: Can't add video input")
                }
            }
            catch let error {
                print(String(describing: Self.self) ,#function, "ERROR: Getting input device: \(error)")
            }
            
            // Audio Input
            guard let audioInputDevice = AVCaptureDevice.default(for: AVMediaType.audio) else { return }
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioInputDevice)
                
                // Add Audio Input
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                } else {
                    print(String(describing: Self.self) ,#function, "Can't Add Audio Input")
                }
            } catch let error {
                print(String(describing: Self.self) ,#function, "Error Getting Input Device: \(error)")
            }
            
            // Video Output
            self.videoFileOutput = AVCaptureMovieFileOutput()
            captureSession.addOutput(self.videoFileOutput!)
            
            // Show Camera Preview
            self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.layer.addSublayer(self.cameraPreviewLayer!)
            self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            let width = self.bounds.width
            let height = self.bounds.height * 0.75
            let yPosition = self.vwLyrics.frame.origin.y + self.vwLyrics.frame.size.height
            self.cameraPreviewLayer?.frame = CGRect(x: 0, y: yPosition, width: width, height: height)
            
            // Bring Record Button To Front & Start Session
            captureSession.startRunning()
            print(captureSession.inputs)
//        }
    }
    
    private func showAlbumPreview() {
        let padding = self.btnRecord.frame.origin.y - (self.vwLyrics.frame.origin.y + self.vwLyrics.frame.size.height)
        let height = padding * 2 / 3
        let width = height
        let xPosition = (self.bounds.width - width)/2
        let yPosition = self.vwLyrics.frame.origin.y + self.vwLyrics.frame.size.height + (padding - height)/2
        self.imvAlbumPreview.frame = CGRect(x: xPosition, y: yPosition, width: width, height: height)
        self.imvAlbumPreview.layer.masksToBounds = true
        self.imvAlbumPreview.layer.cornerRadius = UIDevice.current.userInterfaceIdiom == .phone ? 5.0 : 20.0
        if let detail = self.beatDetail, let coverPhoto = detail["coverPhotoUrl"] as? String {
            self.albumPreview = coverPhoto
        }
        if let urlImage = self.albumPreview, let url = URL(string: urlImage) {
            let processor = DownsamplingImageProcessor(size: self.imvAlbumPreview.bounds.size)
                |> RoundCornerImageProcessor(cornerRadius: 20)
            self.imvAlbumPreview.kf.indicatorType = .activity
            self.imvAlbumPreview.kf.setImage(
                with: url,
                placeholder: UIImage(named: "Image"),
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ])
            {
                result in
                switch result {
                case .success(let value):
                    print("Task done for: \(value.source.url?.absoluteString ?? "")")
                case .failure(let error):
                    print("Job failed: \(error.localizedDescription)")
                }
            }
        }
        else {
            self.imvAlbumPreview.image = UIImage(named: "Image")
        }
        self.imvAlbumPreview.contentMode = .scaleAspectFill
        self.addSubview(self.imvAlbumPreview)
    }
    
    func addPeriodicTimeObserver() {
        if let player = self.player {
            let timeScale = CMTimeScale(NSEC_PER_SEC)
            let time = CMTime(seconds: 0.25, preferredTimescale: timeScale)

            timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
                self.updateHighlightLyrics(time: CMTimeGetSeconds(time))
            }
        }
    }

    func removePeriodicTimeObserver() {
        if let player = self.player, let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}

//MARK: - AVCaptureFileOutputRecordingDelegate
extension RecordingView: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        self.latencyTime = Date().timeIntervalSince1970 * 1000
        print(String(describing: Self.self) ,#function, "1.didStartRecordingTo: \(self.latencyTime)")
        if let player = self.player {
            player.seek(to: CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(1.0)))
            player.playImmediately(atRate: 1.0)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(String(describing: Self.self) ,#function, "ERROR: didFinishRecordingTo: \(error.localizedDescription)")
        }
        else {
            if self.isCancelRecording {
                self.isCancelRecording = false
                return
            }
            print(String(describing: Self.self) ,#function, "outputFileURL: \(outputFileURL)")
            self.encodeVideo(at: outputFileURL) { (videoUrl, mergedUrl, error) in
                if let error = error {
                    print(String(describing: Self.self) ,#function, "ERROR: Conver MOV to MP4: \(error.localizedDescription)")
                    return
                }
                if let videoUrl = videoUrl, let mergedUrl = mergedUrl {
                    print(String(describing: Self.self) ,#function, "MOV to MP4: \(mergedUrl.path)")
                    if let completion = self.onRecordingEnd {
                        completion(["data":["recordedUrl": videoUrl.path, "mergedUrl": mergedUrl.path, "latencyTime": self.latencyTime.rounded()]])
                    }
                }
            }
            
//            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path)) {
//                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(RecordingView.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
//            }
//            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.absoluteString, self, nil, nil)
        }
    }
}

//MARK: - Handle video/audio
extension RecordingView {
    @objc func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let _ = error {
            print(String(describing: Self.self) ,#function, "Error,Video failed to save")
        } else {
            print(String(describing: Self.self) ,#function, "Successfully,Video was saved")
            guard let window = UIApplication.shared.keyWindow else {
                print(String(describing: Self.self) ,#function, "ERROR: Cannot load WINDOW view")
                return
            }
            let alertController = UIAlertController(title: "Saved video success", message: "Your video was saved to Photos", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            window.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func encodeVideo(at videoURL: URL, completionHandler: ((URL?, URL?, Error?) -> Void)?)  {
        self.setHiddenLoadingView(status: false)
        
        let avAsset = AVURLAsset(url: videoURL, options: nil)
            
        let startDate = Date()
            
        //Create Export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completionHandler?(nil, nil, nil)
            return
        }
            
        //Creating temp path to save the converted video
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
            
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                completionHandler?(nil, nil, error)
            }
        }
        self.urlAfterRecorded = filePath
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, 0)
        let range = CMTimeRangeMake(start, avAsset.duration)
        exportSession.timeRange = range
            
        exportSession.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession.status {
            case .failed:
                print(exportSession.error ?? "NO ERROR")
                completionHandler?(nil, nil, exportSession.error)
                self.setHiddenLoadingView(status: true)
            case .cancelled:
                print("Export canceled")
                completionHandler?(nil, nil, nil)
                self.setHiddenLoadingView(status: true)
            case .completed:
                //Video conversion finished
                let endDate = Date()
                    
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful!")
                print(exportSession.outputURL ?? "NO OUTPUT URL")
                if let videoUrl = exportSession.outputURL, let beat = self.beat {
                    let delayAdjusment = self.delay + self.latencyTime.rounded()
                    RecordingView.mergeVideoAndAudio(inputVideo: videoUrl.path, beat: beat, adjustVolumeRecordingVideoIOS: self.adjustVolumeRecordingVideoIOS, adjustVolumeMusicVideoIOS: self.adjustVolumeMusicVideoIOS, delay: delayAdjusment) { (mergedUrl, error) in
                        self.setHiddenLoadingView(status: true)
                        completionHandler?(videoUrl, mergedUrl, error)
                    }
                }
                
                default: break
            }
        })
    }
    
    /// Merge video and audio using MobileFFmpeg lib
    static func mergeVideoAndAudio(inputVideo: String, mergeredPath: String? = "", beat: String, adjustVolumeRecordingVideoIOS: Double, adjustVolumeMusicVideoIOS: Double, delay: Double, completionHandler: ( (URL?, Error?) -> Void)?) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let outputAudioChain = documentsDirectory.appendingPathComponent("audioChain.mp4")
        if FileManager.default.fileExists(atPath: outputAudioChain.path) {
            do {
                try FileManager.default.removeItem(at: outputAudioChain)
            } catch { }
        }
        
        var outputMerge = documentsDirectory.appendingPathComponent("mergeVideo.mp4")
        if let mergeredPath = mergeredPath, let mergeredUrl = URL(string: mergeredPath) {
            outputMerge = mergeredUrl
        }
        
        if FileManager.default.fileExists(atPath: outputMerge.path) {
            do {
                try FileManager.default.removeItem(at: outputMerge)
            } catch { }
        }
        let threshold = pow(10.0, -15/20.0)
        let returnCodeAudioChain = MobileFFmpeg.execute("-y -i \(inputVideo) -af acompressor=level_in=2:threshold=\(threshold):attack=10:release=80:detection=0,highpass=f=180,highshelf=g=1.26:f=7000,aecho=1.0:0.7:20:0.5 \(outputAudioChain.path)")
        
        if returnCodeAudioChain == RETURN_CODE_SUCCESS {
            let returnCodeMerge = MobileFFmpeg.execute("-y -i \(outputAudioChain.path) -i \(beat) -filter_complex [0:a]volume=\(adjustVolumeRecordingVideoIOS)dB[a0];[1:a]volume=\(adjustVolumeMusicVideoIOS)dB[b0];[b0]adelay=\(abs(delay))|\(abs(delay))[b1];[a0][b1]amerge=inputs=2 -b:a 320k -ac 2 -c:v copy -preset ultrafast -movflags +faststart \(outputMerge.path)")
            if returnCodeMerge == RETURN_CODE_SUCCESS {
                print(String(describing: Self.self) ,#function, "MERGE VIDEO SUCCESS")
                completionHandler?(outputMerge, nil)
                return
            }
            else if returnCodeMerge == RETURN_CODE_CANCEL {
                print(String(describing: Self.self) ,#function, "Command execution cancelled by user.")
            }
            else {
                print("Command execution failed with rc=\(returnCodeMerge) and output=\(String(describing: MobileFFmpegConfig.getLastCommandOutput()))")
            }
        }
        else if returnCodeAudioChain == RETURN_CODE_CANCEL {
            print(String(describing: Self.self) ,#function, "Command execution cancelled by user.")
        }
        else {
            print("Command execution failed with rc=\(returnCodeAudioChain) and output=\(String(describing: MobileFFmpegConfig.getLastCommandOutput()))")
        }
        completionHandler?(nil, nil)
    }
}

struct Lyrics : Codable {
    let content : String?
    let end : Double?
    let start : Double?
    let data: [Lyrics]?
    enum CodingKeys: String, CodingKey {
        case content = "content"
        case end = "end"
        case start = "start"
        case data = "data"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        end = try values.decodeIfPresent(Double.self, forKey: .end)
        start = try values.decodeIfPresent(Double.self, forKey: .start)
        data = try (values.decodeIfPresent([Lyrics].self, forKey: .data))
    }
}

//MARK: - UIScrollViewDelegate
extension RecordingView: UITextViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isUserScroll = true
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.isUserScroll = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            self.isUserScroll = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isUserScroll = false
    }
}
