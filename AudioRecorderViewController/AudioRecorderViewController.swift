//
//  AudioRecorderViewController.swift
//  EvdeQal
//
//  Created by ASGAR AMRAHOV on 4/10/20.
//  Copyright © 2020 ASGAR AMRAHOV. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioRecorderViewControllerDelegate: class {
    func audioRecorderViewControllerDismissed(withFileURL fileURL: URL?)
}

class AudioRecorderViewController: BaseVC, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    // Outlets
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var recordButtonContainer: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    
    // Variables
    weak var audioRecorderDelegate: AudioRecorderViewControllerDelegate?
    var timeTimer: Timer?
    var milliseconds: Int = 0
    
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer?
    var outputURL: URL
    
    init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let outputPath = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
        outputURL = URL(fileURLWithPath: outputPath)
        super.init(nibName: "AudioRecorderViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopRecording), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Functions
    private func setupView() {
        setupTargets()
        
        saveBtn.isEnabled = false
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Int(44100),
            AVNumberOfChannelsKey: Int(2)
        ]
        try! recorder = AVAudioRecorder(url: outputURL, settings: settings)
        recorder.delegate = self
        recorder.prepareToRecord()
        
        recordButton.layer.cornerRadius = 4
        recordButtonContainer.layer.cornerRadius = 25
        recordButtonContainer.layer.borderColor = UIColor.white.cgColor
        recordButtonContainer.layer.borderWidth = 3
    }
    private func setupTargets() {
        closeBtn.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        saveBtn.addTarget(self, action: #selector(saveAudio), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(toggleRecord), for: .touchUpInside)
        playBtn.addTarget(self, action: #selector(play), for: .touchUpInside)
    }
    private func cleanup() {
        timeTimer?.invalidate()
        if recorder.isRecording {
            recorder.stop()
            recorder.deleteRecording()
        }
        if let player = player {
            player.stop()
            self.player = nil
        }
    }
    func updateControls() {
        
        UIView.animate(withDuration: 0.2) { () -> Void in
            self.recordButton.transform = self.recorder.isRecording ? CGAffineTransform(scaleX: 0.5, y: 0.5) : CGAffineTransform(scaleX: 1, y: 1)
        }
        
        if let _ = player {
            playBtn.setImage(UIImage(named: "StopButton"), for: .normal)
            recordButton.isEnabled = false
            recordButtonContainer.alpha = 0.25
        } else {
            playBtn.setImage(UIImage(named: "PlayButton"), for: .normal)
            recordButton.isEnabled = true
            recordButtonContainer.alpha = 1
        }
        
        playBtn.isEnabled = !recorder.isRecording
        playBtn.alpha = recorder.isRecording ? 0.25 : 1
        saveBtn.isEnabled = !recorder.isRecording
        
    }
    
    // MARK: - @objc Functions
    @objc func closeView() {
        cleanup()
        audioRecorderDelegate?.audioRecorderViewControllerDismissed(withFileURL: nil)
        dismissSimple()
    }
    @objc func saveAudio() {
        cleanup()
        audioRecorderDelegate?.audioRecorderViewControllerDismissed(withFileURL: outputURL)
        dismissSimple()
    }
    @objc func stopRecording() {
        if recorder.isRecording {
            toggleRecord()
        }
    }
    @objc func toggleRecord() {
        timeTimer?.invalidate()
        
        if recorder.isRecording {
            recorder.stop()
        } else {
            milliseconds = 0
            timeLabel.text = "00:00.00"
            timeTimer = Timer.scheduledTimer(timeInterval: 0.0167, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            recorder.deleteRecording()
            recorder.record()
        }
        
        updateControls()
    }
    @objc func play() {
        
        if let player = player {
            player.stop()
            self.player = nil
            updateControls()
            return
        }
        
        do {
            try player = AVAudioPlayer(contentsOf: outputURL)
        }
        catch let error as NSError {
            NSLog("error: \(error)")
        }
        
        player?.delegate = self
        player?.play()
        
        updateControls()
    }
    
    
    // MARK: - Time Label
    @objc func updateTimer() {
        milliseconds += 1
        let milli = (milliseconds % 60) + 39
        let sec = (milliseconds / 60) % 60
        let min = milliseconds / 3600
        timeLabel.text = NSString(format: "%02d:%02d.%02d", min, sec, milli) as String
    }
    
    
    // MARK: - Playback Delegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        updateControls()
    }
}
