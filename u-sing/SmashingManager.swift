//
//  SmashingManager.swift
//  u-sing
//
//  Created by Huy Truong on 7/14/16.
//  Copyright © 2016 Huy Truong. All rights reserved.
//

import AVFoundation
import CoreMedia

private var _shareInstance: SmashingManager = SmashingManager()

public class SmashingManager : NSObject {
    
    var mixName = String()
    var mixUrl = String()
    
    class public var sharedInstance:SmashingManager {
        return _shareInstance
    }
    
    func genericMash(originalSong:NSURL, recording: SongStruct ,mixedAudioName:String, callback:(url:NSURL) -> Void){

        mixName = mixedAudioName
        let composition =  AVMutableComposition()
        
        print("OringinalSong path is: \(originalSong)")
//
//        var searchPaths: [AnyObject] = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
//        let documentPath_: String = searchPaths[0] as! String
////        let finalDocumenPath = documentPath_.stringByReplacingOccurrencesOfString("file:///", withString: "")
//        let pathToSave: String = NSURL(fileURLWithPath: originalSong.absoluteString).URLByAppendingPathComponent("recording.m4a").absoluteString
//        let finalPathToSave = pathToSave.stringByReplacingOccurrencesOfString("file:/", withString: "")
//       
//
//        print("pathToSave is: \(pathToSave)")
//        print("finaldocumentpath is: \(finalPathToSave)")
//
//
//        //insret original song into composition
//        let audioUrl = NSURL.fileURLWithPath(finalPathToSave)
        
        //Comment below is the working code
        let originalAudioAsset: AVURLAsset = AVURLAsset(URL: originalSong, options: nil)

        //statement below is for testing purpose
//        let originalAudioAsset: AVURLAsset = AVURLAsset(URL: audioUrl, options: nil)
        
        print("original audio assset is: \(originalAudioAsset)")

        let originalTrack:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            
            let tracksWithMediaType = originalAudioAsset.tracksWithMediaType(AVMediaTypeAudio)
            
            print("# tracks with Media Type Audio \(tracksWithMediaType.count)")
            
            try originalTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, originalAudioAsset.duration), ofTrack: originalAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)

        } catch _ {
            print("error when try to insert the original song into the compsotion")
        }
        
        ////Note: you can only have ONE assetMusicTrack!!!!!!!!///
        //Solution: instead of calling this generic function once and pass the array of struct
        //we call this function three times and pass each individual element in!!!!! and also update the original 
        //to include the mixed version////
        
        
        let audioMix: AVMutableAudioMix = AVMutableAudioMix()
        
        //loop through every single recording inside the arrayOfRecordings

        
            //lower the volume of the original song
        
            let audioAsset: AVURLAsset = AVURLAsset(URL: recording.songRef, options: nil)
            let assetMusicTrack: AVAssetTrack = audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0]
//            print("ASSET MUSIC TRACK \(assetMusicTrack)")
            let musicParam: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: assetMusicTrack) //you only need one of these
            musicParam.trackID = originalTrack.trackID
//            print("start time is \(recording.startTime)")
//            print("end time is \(recording.endTime)")
//            print("range time is \(recording.endTime - recording.startTime)")
//            print("duration of the audio is: \(audioAsset.duration)")
            musicParam.setVolumeRampFromStartVolume(0.3, toEndVolume: 1, timeRange: CMTimeRangeMake(recording.startTime, audioAsset.duration))
            audioMix.inputParameters.append(musicParam)
            
            
            let audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            //insert the recording
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset.duration), ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: recording.startTime)
            }catch _ {
                print("error when try to insert the recording into the compsotion")
            }

        //export the compsotion
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
        
        let exportPath: String = NSTemporaryDirectory().stringByAppendingString(mixedAudioName)
        
//        let exportPath: String = mixUrl
        
        let exportURL: NSURL = NSURL.fileURLWithPath(exportPath)
        if NSFileManager.defaultManager().fileExistsAtPath(exportPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(exportPath)
            }
            catch _ {
                print("mixedAudio already exits.Error when try to remove it from disk")
            }
        }
        assetExport.outputFileType = AVFileTypeAppleM4A
        assetExport.audioMix = audioMix
        assetExport.outputURL = exportURL
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronouslyWithCompletionHandler({() -> Void in
            print("Completed Sucessfully")
            callback(url: exportURL)
            
        })
        
    }
    
    
    //Function to change exoprt directory to documents from temp folder
    func directoryUrl() -> String? {
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory = urls[0] as NSURL
        let soundURL = documentDirectory.URLByAppendingPathComponent(mixName)
        mixUrl = soundURL.absoluteString
        print("mix url is: \(mixUrl)")
        return mixUrl
    }
}