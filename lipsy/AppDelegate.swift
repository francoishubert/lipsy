//
//  AppDelegate.swift
//  lipsy
//
//  Created by Hubert Francois on 21/05/2019.
//  Copyright © 2019 Hubert Francois. All rights reserved.
//

import UIKit
import SCSDKLoginKit
import Alamofire
import SwiftyJSON
import FacebookCore
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let url = "https://se9j01lkrd.execute-api.us-east-1.amazonaws.com/dev/endpoint/create"
    let userDefaults = UserDefaults.standard

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if userDefaults.bool(forKey: "hasRunBefore") == false {
            print("The app is launching for the first time. Setting UserDefaults...")
            
            // Update the flag indicator
            userDefaults.set(true, forKey: "hasRunBefore")
            userDefaults.synchronize()
            
            // Run code here for the first launch
            
        } else {
            print("The app has been launched before. Loading UserDefaults...")
            if SCSDKLoginClient.isUserLoggedIn {
                segueTo()
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        // Envoi le token vers votre serveur.
        print("\n\n /**** TOKEN DATA ***/ \(deviceToken) \n\n")
        let deviceTokenString = deviceToken.map {String(format:"%02.2hhx",$0)}.joined()
        print("\n\n /**** TOKEN STRING ***/ \(deviceTokenString) \n\n")
        self.forwardTokenToServer(token: deviceTokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print(userInfo)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.activateApp()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if SCSDKLoginClient.application(app, open: url, options: options) {
            return true
        }
        return true
    }

}

extension AppDelegate {
    func forwardTokenToServer(token: String) {
        let headers: HTTPHeaders = [
            "X-Api-Key": "EdUkRj2minaj28PJ1ULYS2bYLM5zJ3kO1yX94nCr"
        ]
        let parameters: Parameters = [
            "userId": UserDefaults.standard.string(forKey: "userId")!,
            "externalId": UserDefaults.standard.string(forKey: "externalId")!,
            "deviceToken": token
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            if response.result.isSuccess {
                print("Succeed")
            } else {
                print("Failed")
            }
        }
    }
    
    func segueTo() {
        self.window?.rootViewController!.performSegue(withIdentifier: "goToQuizzBuilder", sender: self)
    }
}
