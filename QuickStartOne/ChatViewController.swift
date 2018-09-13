//
//  ChatViewController.swift
//  QuickStartOne
//
//  Created by Jaideep Shah on 9/12/18.
//  Copyright © 2018 Jaideep Shah. All rights reserved.
//

import UIKit
import Stitch
import AVFoundation
import Alamofire
import OpenTok

class ChatViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    var conversation: Conversation?
    var responseId: String?
    @IBOutlet weak var tfVerify: UITextField!
    @IBOutlet weak var subscriberView: UIView!
    
    let videoWidth : CGFloat = 320
    let videoHeight : CGFloat = 240
    //TODO- Add
    let apiKey = ""
    let sessionId = ""
    let token = ""
    
    lazy var session: OTSession = {
        return OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self)!
    }()
    
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    var capturer: ScreenCapturer?
    var otConnected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        conversation?.events.newEventReceived.subscribe(onSuccess: { event in
            guard let event = event as? TextEvent, event.isCurrentlyBeingSent == false else { return }
            guard let text = event.text else { return }
            self.textView.insertText("\n\(text)\n")
            if self.otConnected {
                self.session.signal(withType: "nexmo", string: text, connection: nil, error: nil)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnVerify(_ sender: UIButton) {
        guard let code = tfVerify.text, let requestId = self.responseId else {
            return;
        }
//TODO- Add
        let param: Parameters = ["request_id": requestId,
                          "api_key" : "",
                          "api_secret": "",
                          "code": code]
        Alamofire.request("https://api.nexmo.com/verify/check/json", parameters: param).responseJSON {
            response in
            print("--- Verify SMS API ----")
            print("Response: \(response)")
            if let json = response.result.value as? [String:AnyObject],
                let status = json["status"] as? String {
                
                if Int(status) == 0 {
                    print("Success check done")
                    self.startOpenTok()
                } else {
                    print("Check never worked")
                }

            }
        }
        print(code)
    }
    

    
    func startOpenTok() {
        print("Opentok started")
        doConnect()
        
    }
    @IBAction func sendBtn(_ sender: UIButton) {
        print("Btn clicked for sending messages")
        do {
            // send method
            try conversation?.send(textField.text!)
            
        } catch let error {
            print(error)
        }
    }
    
    @IBAction func twoFactorAuthentication(_ sender: UIButton) {
        requestVerificationWithAPI()
    }
    func requestVerificationWithAPI() {
        //Sending SMS
        //TODO- Add
        let param: Parameters = ["number": "14088924732",
                                 "api_key" : "",
                                 "api_secret": "",
                                 "brand": "Tokbox"]

        Alamofire.request("https://api.nexmo.com/verify/json", parameters: param).responseJSON {
            response in
            print("--- Sent SMS API ----")
            print("Response: \(response)")
            if let json = response.result.value as? [String: AnyObject] {
                self.responseId = json["request_id"] as! String
            }
        }
    }
    
    fileprivate func process(error err: OTError?) {
        if let e = err {
            showAlert(errorStr: e.localizedDescription)
        }
    }
    
    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
    private func doConnect() {
        var error: OTError?
        defer {
            process(error: error)
        }
        session.connect(withToken: token, error: &error)
    }
    
    fileprivate func doPublish() {
        var error: OTError? = nil
        defer {
            process(error: error)
        }
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        publisher = OTPublisher(delegate: self, settings: settings)
        publisher?.videoType = .screen
        publisher?.audioFallbackEnabled = false
        
        capturer = ScreenCapturer(withView: view)
        publisher?.videoCapture = capturer
        
        session.publish(publisher!, error: &error)
    }
    
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            process(error: error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
       
        session.subscribe(subscriber!, error: &error)
        
    }
}

extension ChatViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        self.otConnected = true
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        self.otConnected = false
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated  \(stream.streamId)")
        doSubscribe(stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
    func session(_ session: OTSession, receivedSignalType type: String?, from connection: OTConnection?, with string: String?) {
        if let s = string {
            print (s)
        } else {
            print("signal error")
        }
    }
}
extension ChatViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ChatViewController: OTSubscriberDelegate {
    
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        print("Subscriber connected")
        if let subsView = subscriber?.view {
            
            subsView.frame = CGRect(x: 0, y: 0, width: self.subscriberView.bounds.size.width, height: self.subscriberView.bounds.size.height)
            self.subscriberView.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}
