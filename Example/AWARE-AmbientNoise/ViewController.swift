//
//  ViewController.swift
//  AWARE-AmbientNoise
//
//  Created by Yuuki Nishiyama on 2019/06/12.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework
import Speech

class ViewController: UIViewController {

    let noise = AmbientNoise()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the authorization request
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // The authorization status results in changes to the
            // app’s interface, so process the results on the app’s
            // main queue.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized: break
                case .denied: break
                case .restricted: break
                case .notDetermined: break
                }
            }
        }
        
        // Do any additional setup after loading the view.
        noise.frequencyMin   = 10
        noise.sampleDuration = 10
        noise.sampleSize     = 60
        noise.startSensor()
        noise.setAudioFileGenerationHandler { (url) in
            if let url = url {
                self.recognizeFile(url: url)
            }
        }
        noise.fftDelegate = self
    }

    func recognizeFile(url:URL) {
        guard let myRecognizer = SFSpeechRecognizer() else {
            // A recognizer is not supported for the current locale
            return
        }
        
        if !myRecognizer.isAvailable {
            // The recognizer is not available right now
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url as URL)
        myRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                // Recognition failed, so check error for details and handle it
                return
            }
            
            // Print the speech that has been recognized so far
            if result.isFinal {
                print("  \(result.bestTranscription.formattedString)")
            }
        }
    }

}

extension ViewController: AWAREAmbientNoiseFFTDelegate {
    func fft(_ fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>!, bufferSize: vDSP_Length) {
        if let data = fftData {
            for i in 0..<Int(bufferSize){
                if data[i] > 0.01 {
                    print(i,data[i])
                }
            }
        }
    }
}

