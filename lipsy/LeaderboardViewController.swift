//
//  LeaderboardViewController.swift
//  lipsy
//
//  Created by Hubert Francois on 21/05/2019.
//  Copyright © 2019 Hubert Francois. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SCSDKCreativeKit
import SCSDKLoginKit


class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var totalAnswers = 0
    var anonymousAnswers = 0
    let url = "https://se9j01lkrd.execute-api.us-east-1.amazonaws.com/dev/leaderboard/\(UserDefaults.standard.string(forKey: "userId")!)"
    var scores = [Score]()
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let temporaryFilename = ProcessInfo().globallyUniqueString
    var temporaryFileURL: URL?
    var tapGesture = UITapGestureRecognizer()

    
    @IBOutlet weak var firstPlaceName: UILabel!
    @IBOutlet weak var firstPlaceScore: UILabel!
    @IBOutlet weak var secondPlaceName: UILabel!
    @IBOutlet weak var secondPlaceScore: UILabel!
    @IBOutlet weak var thirdPlaceName: UILabel!
    @IBOutlet weak var thirdPlaceScore: UILabel!
    
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet var shareButton: UIButton!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var card: UIView!
    @IBOutlet var podiumSticker: UIView!
    @IBOutlet weak var seePodiumButton: UIButton!
    @IBOutlet weak var leadTableView: UITableView!
    
    let baseWidth: CGFloat = 320
    var snapAPI: SCSDKSnapAPI?
    var stickerImage: UIImage?
    var sticker: SCSDKSnapSticker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backgroundViewTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        self.seePodiumButton.isEnabled = false
        self.seePodiumButton.alpha = 0.5
        let shareFontSize = 12 * (view.frame.size.width / baseWidth)
        seePodiumButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: shareFontSize)
        seePodiumButton.layer.cornerRadius = 10 * (view.frame.size.width / baseWidth)
        infoLabel.alpha = 0
        getLeaderboard()
        leadTableView.delegate = self
        leadTableView.dataSource = self
        leadTableView.register(UINib(nibName: "TableViewCell1", bundle: nil), forCellReuseIdentifier: "customCell")
        leadTableView.separatorColor = UIColor.clear
        leadTableView.showsVerticalScrollIndicator = false
        snapAPI = SCSDKSnapAPI()
        temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
    }
    
    @objc func backgroundViewTapped(_ sender: UITapGestureRecognizer) {
        remove()
    }

    func remove() {
        backgroundView.removeFromSuperview()
        podiumSticker.removeFromSuperview()
        shareButton.removeFromSuperview()
    }

    @IBAction func shareTapped(_ sender: UIButton) {
        share()
    }

    @IBAction func podiumTapped(_ sender: UIButton) {
        for i in 0...2 {
            switch (i) {
            case 0:
                firstPlaceName.text = scores[i].friendName
                firstPlaceScore.text = scores[i].rightAnswer + "👍"
            case 1:
                secondPlaceName.text = scores[i].friendName
                secondPlaceScore.text = scores[i].rightAnswer + "👍"
            case 2:
                thirdPlaceName.text = scores[i].friendName
                thirdPlaceScore.text = scores[i].rightAnswer + "👍"
            default:
                return
            }
        }
        podiumSticker.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        [
            backgroundView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            backgroundView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
            backgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0),
            backgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0)
        ].forEach{$0.isActive = true}
        backgroundView.alpha = 0.5
        view.addSubview(podiumSticker)
        view.addSubview(shareButton)
        [
            podiumSticker.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.80),
            podiumSticker.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            podiumSticker.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ].forEach{$0.isActive = true}
        [
            shareButton.topAnchor.constraint(equalTo: self.podiumSticker.bottomAnchor, constant: 10),
            shareButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            shareButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.30),
            shareButton.heightAnchor.constraint(equalTo: self.shareButton.widthAnchor, multiplier: 28/62)
        ].forEach{$0.isActive = true}
        view.layoutIfNeeded()
        let shareFontSize = 15 * (view.frame.size.width / baseWidth)
        shareButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: shareFontSize)
        shareButton.layer.cornerRadius = 10 * (view.frame.size.width / baseWidth)
        card.layer.cornerRadius = 20 * (view.frame.size.width / baseWidth)
        card.layer.masksToBounds = true

    }

    func share() {
        view.isUserInteractionEnabled = false
        let snapContent = SCSDKNoSnapContent()
        let stickerImageUrl = png(with: podiumSticker)
        let sticker = SCSDKSnapSticker(stickerUrl: stickerImageUrl!, isAnimated: false)
        snapContent.sticker = sticker
        snapAPI?.startSending(snapContent) { [weak self] (error: Error?) in
            self?.remove()
            self?.view.isUserInteractionEnabled = true
        }
    }

    func png(with view: UIView) -> URL? {
        UIGraphicsBeginImageContextWithOptions(view.layer.frame.size, false, 0.0)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let data = image.pngData()
        let fileURL = self.temporaryFileURL!
        try? data!.write(to: fileURL)
        return fileURL
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(paths[0])
        return paths[0]
    }

    func getLeaderboard() {
        let headers: HTTPHeaders = [
            "X-Api-Key": "EdUkRj2minaj28PJ1ULYS2bYLM5zJ3kO1yX94nCr",
        ]
        Alamofire.request(url, headers: headers).responseJSON { response in
            if response.result.isSuccess {
                let responseJSON = JSON(response.result.value!)
                self.totalAnswers = responseJSON["totalAnswers"].intValue
                self.anonymousAnswers = responseJSON["anonymousAnswers"].intValue
                let scoreItems = responseJSON["leaderBoard"]["Items"]
                for scoreItem in scoreItems.arrayValue {
                    let score = Score()
                    score.friendName = scoreItem["pk"].stringValue
                    score.consecutiveAnswer = scoreItem["consecutiveAnswer"].stringValue
                    score.rightAnswer = scoreItem["rightAnswer"].stringValue
                    score.questionAnswered =  scoreItem["questionAnswered"].stringValue
                    self.scores.append(score)
                }
                if self.scores.count == 0 {
                    self.infoLabel.alpha = 1
                    self.seePodiumButton.isEnabled = false
                    self.seePodiumButton.alpha = 0.5
                } else if self.scores.count < 3{
                    self.seePodiumButton.isEnabled = false
                    self.seePodiumButton.alpha = 0.5
                } else {
                    self.seePodiumButton.isEnabled = true
                    self.seePodiumButton.alpha = 1
                }
                self.leadTableView.reloadData()
                if self.anonymousAnswers != 0 {
                    self.infoLabel.alpha = 1
                    self.infoLabel.text = "\(self.totalAnswers) total answers (\(self.anonymousAnswers) anonymous)"
                }
            } else {
                self.seePodiumButton.isEnabled = false
                self.seePodiumButton.alpha = 0.5
                let alert = UIAlertController(title: "Error", message: "Connection Issues", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! TableViewCell1

        switch (indexPath.row) {
            case 0:
                cell.friendName.text = scores[indexPath.row].friendName + "🥇"
            case 1:
                cell.friendName.text = scores[indexPath.row].friendName + "🥈"
            case 2:
                cell.friendName.text = scores[indexPath.row].friendName + "🥉"
            default:
                cell.friendName.text = scores[indexPath.row].friendName
        }
        cell.quizzAnswered.text = scores[indexPath.row].questionAnswered + "❓"
        cell.rightAnswer.text = scores[indexPath.row].rightAnswer + "👍"
        cell.consecutiveAnswer.text = scores[indexPath.row].consecutiveAnswer + "🔥"
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return scores.count

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 35.0;
    }
    
}
