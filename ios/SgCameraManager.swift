//
//  SgCameraManager.swift
//  BVLinearGradient
//
//  Created by Trai Nguyen on 7/9/20.
//

@objc(SgCameraManager)
class SgCameraManager: NSObject {

    @objc(remerge:recordedUrl:mergeredUrl:beat:adjustVolumeRecordingVideoIOS:adjustVolumeMusicVideoIOS:callback:)
    func remerge(adjustment: Double,
                 recordedUrl: String,
                 mergeredUrl: String,
                 beat: String,
                 adjustVolumeRecordingVideoIOS: Double,
                 adjustVolumeMusicVideoIOS: Double,
                 callback: @escaping RCTResponseSenderBlock) {
        RecordingView.mergeVideoAndAudio(inputVideo: recordedUrl,
                                         mergeredPath: mergeredUrl,
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
