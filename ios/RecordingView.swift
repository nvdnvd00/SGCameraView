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
    //UI
    let RECORD_BUTTON_HEIGHT: CGFloat = 60
    private var loadingView: UIView?
    private var btnRecord = UIButton(type: .custom)
    private var vwLyrics = UIView(frame: .zero)
    private var txvLyrics = UITextView(frame: .zero)
    private var imvAlbumPreview = UIImageView(frame: .zero)
    
    //Outside data
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
    
    //Inside data
    private var arrLyricsModel: [Lyrics] = []
    private var isUserScroll: Bool = false
    private var isCancelRecording: Bool = false
    private var latencyTime: Double = 0.0
    
    //Audio mode
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
        if self.imvAlbumPreview.frame == .zero {
            self.showAlbumPreview()
            self.bringSubviewToFront(self.btnRecord)
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
            self.bringSubviewToFront(self.btnRecord)
            self.btnRecord.isUserInteractionEnabled = true
            self.startRecordByAudioKit()
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.endRecordByAudioKit()
        }
    }
    
    @objc func cancelRecording() {
        print(String(describing: Self.self) ,#function)
        isCancelRecording = true
        
        if let beatPlayer = self.beatPlayer, beatPlayer.isPlaying {
            self.mixerBooster.gain = 0
            self.beatPlayer?.stop()
            self.periodicFunc?.stop()
            self.recorder.stop()
        }
    }
    
    deinit {
        imvAlbumPreview.frame = .zero
        imvAlbumPreview.removeFromSuperview()
        
        loadingView?.removeFromSuperview()
        loadingView = nil
        
        self.txvLyrics.removeFromSuperview()
        self.vwLyrics.removeFromSuperview()
        self.beatPlayer?.stop()
        self.periodicFunc?.stop()
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
        
        let indicator = UIActivityIndicatorView.init(style: .whiteLarge)
        self.loadingView?.addSubview(indicator)
        indicator.center = self.center
        indicator.startAnimating()
        
        self.loadingView?.isHidden = true
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
                self.bringSubviewToFront(loadingView)
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
            try AKManager.stop()
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
        
        AKManager.output = mainMixer
        do {
            self.periodicFunc?.start()
            if let periodic = self.periodicFunc {
                try AKManager.start(withPeriodicFunctions: periodic)
            }
            else {
                try AKManager.start()
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
        do {
            try recordPlayer.load(audioFile: tape)
        } catch {
            print(error.localizedDescription)
        }
        
        
        if let _ = recordPlayer.audioFile?.duration {
            self.periodicFunc?.stop()
            self.beatPlayer?.stop()
            recorder.stop()
            tape.exportAsynchronously(name: "rendered-video.mp4",
                                      baseDir: .documents,
                                      exportFormat: .mp4) { audioFile , exportError in
                if let newAudioFile = audioFile {
                    DispatchQueue.main.async {
                        if let artwork = self.imvAlbumPreview.image {
                            self.addArtwork(srcSoundFileURL: newAudioFile.url, artwork: artwork)
                        }
                        else {
                            if let completion = self.onRecordingEnd {
                                completion(["data":["recordedUrl": newAudioFile.url.path, "mergedUrl": newAudioFile.url.path, "latencyTime": self.latencyTime, "type": 1]])
                            }
                            else {
                                print("onRecordingEnd nil")
                            }
                        }
                    }
                }
                else if let error = exportError {
                    AKLog("Export Failed \(error)")
                }
            }
        }
    }
    
    private func addArtwork(srcSoundFileURL: URL, artwork: UIImage) {
        //Creating temp path to save the converted video
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("add-artwork-video.mp4")
        
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                //                completionHandler?(nil, nil, error)
            }
        }
        
        let urlAsset = AVURLAsset(url: srcSoundFileURL)
        let assetExportSession: AVAssetExportSession! = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetPassthrough)
        
        
        let soundFileMetadata = AVMutableMetadataItem()
        soundFileMetadata.keySpace = .common
        soundFileMetadata.key = AVMetadataKey.commonKeyArtwork as NSCopying & NSObjectProtocol
        soundFileMetadata.value = artwork.jpegData(compressionQuality: 1) as (NSCopying & NSObjectProtocol)?
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.outputURL = filePath
        assetExportSession.metadata = [soundFileMetadata]
        assetExportSession.exportAsynchronously(completionHandler: {
            switch assetExportSession.status {
            case .failed:
                print(assetExportSession.error ?? "NO ERROR")
            case .cancelled:
                print("Export canceled")
            case .completed:
                //Video conversion finished
                print("Successful!")
                print(assetExportSession.outputURL ?? "NO OUTPUT URL")
                if let videoUrl = assetExportSession.outputURL {
                    if let completion = self.onRecordingEnd {
                        completion(["data":["recordedUrl": videoUrl.path, "mergedUrl": videoUrl.path, "latencyTime": self.latencyTime, "type": 1]])
                    }
                    else {
                        print("onRecordingEnd nil")
                    }
                }
            default: break
            }
        })
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
        
        if self.isUserScroll == false && finalString.count > 0 {
            if let endPos = txvLyrics.position(from: txvLyrics.beginningOfDocument, offset: highlightLyricsString.count), let textRange = txvLyrics.textRange(from: txvLyrics.beginningOfDocument, to: endPos) {
                let lyricsHeight = self.txvLyrics.frame.size.height
                
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
                ], completionHandler:
                    {
                        result in
                        switch result {
                        case .success(let value):
                            print("Task done for: \(value.source.url?.absoluteString ?? "")")
                        case .failure(let error):
                            print("Job failed: \(error.localizedDescription)")
                        }
                    })
        }
        else {
            self.imvAlbumPreview.image = UIImage(named: "Image")
        }
        self.imvAlbumPreview.contentMode = .scaleAspectFill
        self.addSubview(self.imvAlbumPreview)
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
