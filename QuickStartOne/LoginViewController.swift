//
//  LoginViewController.swift
//  QuickStartOne
//
//  Created by Jaideep Shah on 9/12/18.
//  Copyright © 2018 Jaideep Shah. All rights reserved.
//

import UIKit
import Stitch
struct Authenticate {
    //TODO- Add
    static let userJWT = ""
}
class LoginViewController: UIViewController {
    
    let client: ConversationClient = {
        return ConversationClient.instance
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func loginBtn(_ sender: UIButton) {
        print("DEMO - login button pressed.")
        
        let token = Authenticate.userJWT
        
        print("DEMO - login called on client.")
        
        client.login(with: token).subscribe(onSuccess: {
            
            print("DEMO - login susbscribing with token.")

            if let user = self.client.account.user {
                print("DEMO - login successful and here is our \(user)")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "ChatViewController")
                let newViewController = controller as? ChatViewController
                if let c = newViewController {
                    c.conversation = self.client.conversation.conversations.first
                    self.present(c, animated: true, completion: nil)
                }
                
            } // insert activity indicator to track subscription
            
            
        }, onError: { [weak self] error in
           
            print(error.localizedDescription)
            
            // remove to a function
            let reason: String = {
                switch error {
                case LoginResult.failed: return "failed"
                case LoginResult.invalidToken: return "invalid token"
                case LoginResult.sessionInvalid: return "session invalid"
                case LoginResult.expiredToken: return "expired token"
                case LoginResult.success: return "success"
                default: return "unknown"
                }
            }()
            
            print("DEMO - login unsuccessful with \(reason)")
            
        }) //.addDisposableTo(client.disposeBag)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    // prepare(for segue:)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // setting up a segue
        let chatVC = segue.destination as? ChatViewController
        
        // passing a reference to the conversation
        chatVC?.conversation = client.conversation.conversations.first
        
    }

}
