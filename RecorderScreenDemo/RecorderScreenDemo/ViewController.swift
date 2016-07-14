//
//  ViewController.swift
//  RecorderScreenDemo
//
//  Created by xun.liu on 16/7/13.
//  Copyright © 2016年 TVM. All rights reserved.
//

import UIKit
import ReplayKit

//#if TARGET_IPHONE_SIMULATOR
//    let SIMULATOR:Bool = true
//#else
//    let SIMULATOR = false
//#endif

#if arch(i386) || arch(x86_64)
    
    let SIMULATOR:Bool = true
#else
    let SIMULATOR = false
    
#endif

class ViewController: UIViewController, RPScreenRecorderDelegate, RPPreviewViewControllerDelegate {

    @IBOutlet weak var startRecordingButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var timerLabel: UILabel!
    
    private let recorder = RPScreenRecorder.sharedRecorder()
    var timer:NSTimer = NSTimer()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if SIMULATOR {
            NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.showSimulatorWarning), userInfo: nil, repeats: false)
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        recorder.delegate = self
        activityView.hidden = true
        buttonEnabledControl(recorder.recording)
    }

    @IBAction func startRecordingAction(sender: AnyObject) {
        activityView.hidden = false
        
        // start recording
        recorder.startRecordingWithMicrophoneEnabled(true) { [unowned self] (error) in
            dispatch_async(dispatch_get_main_queue()) {
                [unowned self] in
                self.activityView.hidden = true
            }
            
            if let error = error {
                print("Failed start recording: \(error.localizedDescription)")
                return
            }
            
            print("Start recording")
            self.buttonEnabledControl(true)
        
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.updateTimeString), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func stopRecordingAction(sender: AnyObject) {
        activityView.hidden = false
        
        //end recording
        recorder.stopRecordingWithHandler({ [unowned self] (previewViewController, error) in
            dispatch_async(dispatch_get_main_queue()) {
                self.activityView.hidden = true
            }
            
            self.buttonEnabledControl(false)
            
            if let error = error {
                print("Failed stop recording: \(error.localizedDescription)")
                return
            }
            
            print("Stop recording")
            previewViewController?.previewControllerDelegate = self
            
            self.timer.invalidate()
            
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                // show preview vindow
                self.presentViewController(previewViewController!, animated: true, completion: nil)
            }
        })
    }
    
    //MARK: - Helper
    //control the enabled each button
    private func buttonEnabledControl(isRecording: Bool) {
        dispatch_async(dispatch_get_main_queue()) { 
            [unowned self] in
            
            let enabledColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
            let disabledColor = UIColor.lightGrayColor()
            
            if !self.recorder.available {
                self.startRecordingButton.enabled = false
                self.startRecordingButton.backgroundColor = disabledColor
                self.stopRecordingButton.enabled = false
                self.stopRecordingButton.backgroundColor = disabledColor
                
                return
            }
            
            self.startRecordingButton.enabled = !isRecording
            self.startRecordingButton.backgroundColor = isRecording ? disabledColor : enabledColor
            self.stopRecordingButton.enabled = isRecording
            self.stopRecordingButton.backgroundColor = isRecording ? enabledColor : disabledColor
        }
    }
    
    private func createHaloAt(location: CGPoint, withRadius radius: CGFloat) {
        let halo = PulsingHaloLayer()
        halo.repeatCount = 1
        halo.position = location
        halo.radius = radius * 2.0
        halo.fromValueForRadius = 0.5
        halo.keyTimeForHalfOpacity = 0.7
        halo.animationDuration = 0.8
        view.layer.addSublayer(halo);
    }
    
    func showSimulatorWarning() {
        let actionOK = UIAlertAction(title: "OK", style: .Default, handler: nil)
//        let actionCancel = UIAlertAction(title: "cancel", style: .Cancel, handler: nil)
        
        let alert = UIAlertController(title: "ReplayKit不支持模拟器", message: "请使用真机运行这个Demo工程", preferredStyle: .Alert)
        alert.addAction(actionOK)
//        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showSystemVersionWarning() {
        let actionOK = UIAlertAction(title: "OK", style: .Default, handler: nil)
        let alert = UIAlertController(title: nil, message: "系统版本需要是iOS9.0及以上才支持ReplayKit", preferredStyle: .Alert)
        alert.addAction(actionOK)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateTimeString() {
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "HH:mm:ss"
        let dateString:String = dateFormat.stringFromDate(NSDate())
        timerLabel.text = dateString
    }
    
    // MARK: - Touch Handler
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInView(view)
            let radius = touch.majorRadius
            
            createHaloAt(location, withRadius: radius)
        }
    }
    
    
    // MARK: - RPScreenRecorderDelegate
    // called after stopping the recording
    func screenRecorder(screenRecorder: RPScreenRecorder, didStopRecordingWithError error: NSError, previewViewController: RPPreviewViewController?) {
        print("Stop Recording ...\n");
    }
    
    // called when the recorder availability has changed
    func screenRecorderDidChangeAvailability(screenRecorder: RPScreenRecorder) {
        let availability = screenRecorder.available
        print("Availability: \(availability)\n");
    }
    
    // MARK: - RPPreviewViewControllerDelegate
    // called when preview is finished
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        print("Preview finish");
        
        dispatch_async(dispatch_get_main_queue()) { 
            [unowned previewController] in
            // close preview window
            previewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


