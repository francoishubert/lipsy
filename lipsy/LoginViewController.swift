//
//  ViewController.swift
//  lipsy
//
//  Created by Hubert Francois on 21/05/2019.
//  Copyright © 2019 Hubert Francois. All rights reserved.
//

import UIKit
import SCSDKLoginKit
import SCSDKBitmojiKit
import Alamofire
import SwiftyJSON
import SVProgressHUD


class LoginViewController: UIViewController {
    
    let baseWidth: CGFloat = 320
    var tapGesture = UITapGestureRecognizer()
    let url = "https://se9j01lkrd.execute-api.us-east-1.amazonaws.com/dev/user/create"
    let graphQLQuery = "{me{displayName, bitmoji{avatar}, externalId}}"
    let variables = ["page": "bitmoji"]
    var externalId : String?
    var bitmojiUrl : String?
    var name : String?

    let dispatchGroup = DispatchGroup()
    
    @IBOutlet weak var snap: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.snapTapped(_:)))
        tapGesture.numberOfTapsRequired = 1 
        tapGesture.numberOfTouchesRequired = 1
        snap.addGestureRecognizer(tapGesture)
        snap.isUserInteractionEnabled = true
        snap.layer.cornerRadius = 10 * (view.frame.size.width / baseWidth)
    }
    
    @objc func snapTapped(_ sender: UITapGestureRecognizer) {
        login()
    }
    
    func segueTo() {
        performSegue(withIdentifier: "goToQuizzBuilder", sender: self)
    }
    
    func login() {
        SCSDKLoginClient.login(from: self) { (success : Bool, error : Error?) in
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = false
                SVProgressHUD.show()
            }
            if success {
                DispatchQueue.main.async {
                    self.createUser()
                }
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    let alert = UIAlertController(title: "Error", message: "The software couldn't be completed. Software caused connection abort", preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { (UIAlertAction) in
                        self.login()
                    })
                    let cancelAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(cancelAction)
                    alert.addAction(retryAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getBitmojiData() {
        dispatchGroup.enter()
        SCSDKLoginClient.fetchUserData(withQuery: self.graphQLQuery, variables: self.variables, success: { (resources: [AnyHashable: Any]?) in
            guard let resources = resources,
                let data = resources["data"] as? [String: Any],
                let me = data["me"] as? [String: Any] else { return }
            
            let externalId = me["externalId"] as? String
            print("externalId : " + externalId!)
            self.externalId = externalId
            let displayName = me["displayName"] as? String
            print("name : " + displayName!)
            self.name = displayName
            var bitmojiAvatarUrl: String?
            if let bitmoji = me["bitmoji"] as? [String: Any] {
                bitmojiAvatarUrl = bitmoji["avatar"] as? String
                self.bitmojiUrl = bitmojiAvatarUrl
            }
            self.dispatchGroup.leave()
        }, failure: { (error: Error?, isUserLoggedOut: Bool) in
            print("is user logged out : \(isUserLoggedOut)")
        })
    }
    
    func createUser() {
        getBitmojiData()
        dispatchGroup.notify(queue: .main) {
            let parameters: Parameters = [
                "externalId": self.externalId!,
                "name": self.name!
            ]
            let headers: HTTPHeaders = [
                "X-Api-Key": "EdUkRj2minaj28PJ1ULYS2bYLM5zJ3kO1yX94nCr",
            ]
            Alamofire.request(self.url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                if response.result.isSuccess {
                    let responseJSON = JSON(response.result.value!)
                    let userId = responseJSON["userId"].stringValue
                    UserDefaults.standard.set(userId, forKey: "userId")
                    UserDefaults.standard.set(self.name, forKey: "name")
                    UserDefaults.standard.set(self.externalId, forKey: "externalId")
                    UserDefaults.standard.set(self.bitmojiUrl, forKey: "bitmojiUrl")
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    self.performSegue(withIdentifier: "goToQuizzBuilder", sender: self)
                } else {
                    SVProgressHUD.dismiss()
                    self.view.isUserInteractionEnabled = true
                    let alert = UIAlertController(title: "Error", message: "Connection Issues", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func unwindToLogin(_ sender: UIStoryboardSegue) {}
    
}

