//
//  SpeechRecognizer.swift
//  ARHOME112
//
//  Created by Ugol Ugol on 22/05/2018.
//  Copyright © 2018 Ugol Ugol. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    
    // speech recognition variables
    var word: String = ""
    
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var audioEngine = AVAudioEngine()
    
    func startRecording() throws {
        
        // Cancel previous task if it's running
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create recognition request")
        }
        recognitionTask = speechRecognizer.recognitionTask(with: (recognitionRequest), resultHandler: {result, error in
            
            var isFinal = false
            
            guard let result = result else { return }
            isFinal = result.isFinal
            self.word = self.getLastResult(results: result.bestTranscription)
            print(self.word)
            
            if error != nil || isFinal || self.word.count > 0{
                self.recognitionRequest?.endAudio()
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
    }
    
    func getLastResult(results: SFTranscription) -> String{
        
        var lastString: String = ""
        let bstring = results.formattedString
        
        for segment in results.segments {
            let indexTo = bstring.index(bstring.startIndex, offsetBy: segment.substringRange.location)
            lastString = String(bstring.suffix(from: indexTo))
        }
        
        return lastString
    }
    
    func clear(){
        self.word = ""
    }
    

}
