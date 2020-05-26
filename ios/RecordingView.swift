//
//  RecordingView.swift
//  MyRNApp
//
//  Created by Trai Nguyen on 5/25/20.
//

import UIKit
import AVKit

class RecordingView: UIView {
  let RECORD_BUTTON_HEIGHT: CGFloat = 60
  private var videoFileOutput: AVCaptureMovieFileOutput?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private var player: AVPlayer?
  private var loadingView: UIView?
  private var btnRecord = UIButton(type: .custom)
  
  @objc var beat: String?
  @objc var lyric: String?
  @objc var onRecordingEnd: RCTDirectEventBlock?
  
  override func draw(_ rect: CGRect) {
      print(String(describing: Self.self) ,#function, "TN_TEST: \(rect)")
      self.frame = CGRect(origin: .zero, size: rect.size)
      updateRecordButtonPosition()
      if self.loadingView == nil {
        setupLoadingView()
      }
      if self.cameraPreviewLayer == nil {
        self.showCameraPreview()
        self.bringSubview(toFront:self.btnRecord)
      }
  }
    
  override init(frame: CGRect) {
     super.init(frame: frame)
     setupView()
   }
  
   required init?(coder aDecoder: NSCoder) {
     super.init(coder: aDecoder)
     setupView()
   }
  
  private func setupView()  {
    self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    setupRecordButton()
    setupAudioSession()
  }
    
  fileprivate func updateRecordButtonPosition() {
    let xPosition: CGFloat = self.frame.size.width/2 - RECORD_BUTTON_HEIGHT/2
    let yPosition: CGFloat = self.frame.size.height - RECORD_BUTTON_HEIGHT - 10
    if self.btnRecord.isHidden {
      self.btnRecord.isHidden = false
    }
    self.btnRecord.frame = CGRect(x: xPosition, y: yPosition, width: RECORD_BUTTON_HEIGHT, height: RECORD_BUTTON_HEIGHT)
  }
  
  func startRecording() {
    DispatchQueue.main.async {
      guard let beat = self.beat else {
          print(String(describing: Self.self) ,#function, "ERROR: You must set beat url")
          return
      }
      guard let loadingView = self.loadingView else {
        print(String(describing: Self.self) ,#function, "ERROR: Cannot load WINDOW view")
        return
      }
      loadingView.isHidden = false
      self.playAudio(urlString: beat)
      self.bringSubview(toFront:loadingView)
    }
  }
  
  func stopRecording() {
    DispatchQueue.main.async {
      self.videoFileOutput?.stopRecording()
      if let player = self.player {
          player.pause()
      }
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
      if let player =  object as? AVPlayer, keyPath == "timeControlStatus" {
          if player.timeControlStatus == .playing {
              if let videoFileOutput = self.videoFileOutput, !videoFileOutput.isRecording {
                  player.pause()
                  realStartRecording()
                  return
              }
              print(String(describing: Self.self) ,#function, "2.is playing audio: \(Date().timeIntervalSince1970 * 1000)")
          }
      }
  }
}

//MARK: - Setup
extension RecordingView {
  fileprivate func setupRecordButton() {
    self.btnRecord.frame = CGRect(x: 0, y: 0, width: RECORD_BUTTON_HEIGHT, height: RECORD_BUTTON_HEIGHT)
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
      startRecording()
      sender.isUserInteractionEnabled = false
    }
    sender.isSelected = !sender.isSelected
  }
  
    fileprivate func setupLoadingView() {
        loadingView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        loadingView?.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        self.addSubview(loadingView!)
        
        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        loadingView?.addSubview(indicator)
        indicator.center = self.center
        indicator.startAnimating()
        
        loadingView?.isHidden = true
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
}

//MARK: - Private function
extension RecordingView {
    fileprivate func playAudio(urlString: String) {
        let videoURL = URL(string: urlString)
        let newPlayer = AVPlayer(url: videoURL!)
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
        self.player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
    }
    
    fileprivate func showCameraPreview() {
        let captureSession = AVCaptureSession()
        
        // Preset For 720p
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        // Video Input
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: camera!)
            
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
        videoFileOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(videoFileOutput!)
        
        // Show Camera Preview
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        let width = self.bounds.width
        let height = self.bounds.height
        cameraPreviewLayer?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Bring Record Button To Front & Start Session
        captureSession.startRunning()
        print(captureSession.inputs)
    }
}

//MARK: - AVCaptureFileOutputRecordingDelegate
extension RecordingView: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print(String(describing: Self.self) ,#function, "1.didStartRecordingTo: \(Date().timeIntervalSince1970 * 1000)")
        if let player = self.player {
            player.playImmediately(atRate: 1.0)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(String(describing: Self.self) ,#function, "ERROR: didFinishRecordingTo: \(error.localizedDescription)")
        }
        else {
            print(String(describing: Self.self) ,#function, "outputFileURL: \(outputFileURL)")
            if let completion = self.onRecordingEnd {
              completion(["data":["uri": outputFileURL.path]])
            }
//            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputFileURL.path)) {
//                UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(RecordingView.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
//            }
//            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.absoluteString, self, nil, nil)
        }
    }
    
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

}
