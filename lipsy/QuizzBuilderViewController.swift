//
//  QuizzBuilderViewController.swift
//  lipsy
//
//  Created by Hubert Francois on 21/05/2019.
//  Copyright © 2019 Hubert Francois. All rights reserved.
//

import UIKit
import SCSDKCreativeKit
import SCSDKBitmojiKit
import SCSDKLoginKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import UserNotifications
import FacebookCore
import FBSDKCoreKit


class QuizzBuilderViewController: UIViewController {
    
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var questionTextView: UITextView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var randomQuestionView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logo: UILabel!
    @IBOutlet weak var swipeUpLabel: UILabel!
    
    // answer Views - Text Views
    @IBOutlet weak var answerAView: UIView!
    @IBOutlet weak var answerBView: UIView!
    @IBOutlet weak var answerCView: UIView!
    @IBOutlet weak var answerDView: UIView!
    @IBOutlet weak var answerATextView: UITextView!
    @IBOutlet weak var answerBTextView: UITextView!
    @IBOutlet weak var answerCTextView: UITextView!
    @IBOutlet weak var answerDTextView: UITextView!
    
    // answer Buttons
    @IBOutlet weak var buttonA: UIButton!
    @IBOutlet weak var buttonB: UIButton!
    @IBOutlet weak var buttonC: UIButton!
    @IBOutlet weak var buttonD: UIButton!
    @IBOutlet weak var leaderboardLabel: UILabel!
    
    // add and clear button
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    // snap related Views
    @IBOutlet weak var shareSnapView: UIView!
    @IBOutlet weak var shareSnapLabel: UILabel!
    @IBOutlet weak var bitmojiImageView: UIImageView!
    
    // all tap gestures
    var tapGesture1 = UITapGestureRecognizer()
    var tapGesture2 = UITapGestureRecognizer()
    var tapGesture3 = UITapGestureRecognizer()
    var tapGesture4 = UITapGestureRecognizer()
    
    var questions = [JSON]()
    var answerTextViews = [UITextView]()
    var answerList = [UITextView]()
    var answerButtons = [UIButton]()
    var answerViews = [UIView]()
    
    var selectedTextView : UITextView?
    var selectedAnswer: String?
    var selectedAnswerView: UIView?
    var selectedAnswerButton: UIButton?
    var selectedAnswerTextView: UITextView?
    
    //snap sharing
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let temporaryFilename = ProcessInfo().globallyUniqueString
    var temporaryFileURL: URL?
    var snapAPI: SCSDKSnapAPI?
    var stickerImage: UIImage?
    var sticker: SCSDKSnapSticker?
    
    //url lipsy-core service
    let url = "https://se9j01lkrd.execute-api.us-east-1.amazonaws.com/dev/quizz/create"
    let urlRandomQuestion = "https://se9j01lkrd.execute-api.us-east-1.amazonaws.com/dev/randomQuestion"
    
    let baseWidth: CGFloat = 320
    let green = UIColor(red: 0, green: 0.91, blue: 0.28, alpha: 1.0)
    let red = UIColor(red: 1.00, green:0.00, blue: 0.24, alpha: 1.0)
    let white = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    @objc func didFetchRandomQuestion(_ sender: UITapGestureRecognizer) {
        let name = AppEvents.Name("getRandomQuestion")
        AppEvents.logEvent(name)
        if questions.count == 0 {
            let alert = UIAlertController(title: "Error", message: "Connection Issues", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            var randomQuestion = questions.randomElement()
            let fontSize = 14 * (view.frame.size.width / baseWidth)
            self.questionTextView.text = randomQuestion!["Question"].stringValue
            self.questionTextView.textColor = UIColor.black
            questionTextView.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            self.textViewDidChange(self.questionTextView)
        }
    }
    
    @IBAction func cleared(_ sender: UIButton) {
        clearCard()
    }

    @IBAction func addNewAnswer(_ sender: UIButton) {
        disable(tapGesture3, shareSnapView)
        if !answerCView.isDescendant(of: cardView) {
            answerList.append(answerCTextView)
            setupAnswerC()
        } else if !answerDView.isDescendant(of: cardView) {
            answerList.append(answerDTextView)
            addButton.removeFromSuperview()
            setupAnswerD()
        }
    }
    
    func setupAnswerD() {
        answerDView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(answerDView)
        [
            answerDView.topAnchor.constraint(equalTo: self.answerCView.bottomAnchor, constant: 15),
            answerDView.bottomAnchor.constraint(equalTo: self.cardView.bottomAnchor, constant: -20),
            answerDView.widthAnchor.constraint(equalTo: self.cardView.widthAnchor, multiplier: 0.80),
            answerDView.heightAnchor.constraint(equalTo: self.answerCView.widthAnchor, multiplier: 28/120),
            answerDView.centerXAnchor.constraint(equalTo: self.cardView.centerXAnchor)
            
            ].forEach{$0.isActive = true}
        view.layoutIfNeeded()
        answerDView.layer.cornerRadius = answerDView.frame.size.height / 2
        buttonD.layer.cornerRadius = buttonA.frame.size.height / 2
        buttonD.layer.borderWidth = 1
        buttonD.layer.borderColor = UIColor.lightGray.cgColor
        answerDTextView.becomeFirstResponder()
    }
    
    func setupAnswerC() {
        for constraint in addButton.superview!.constraints {
            if constraint.firstAttribute == .top && constraint.firstItem?.tag == addButton.tag {
                constraint.isActive = false
            }
        }
        answerCView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(answerCView)
        [
            answerCView.topAnchor.constraint(equalTo: self.answerBView.bottomAnchor, constant: 15),
            addButton.topAnchor.constraint(equalTo: self.answerCView.bottomAnchor, constant: 15),
            answerCView.widthAnchor.constraint(equalTo: self.cardView.widthAnchor, multiplier: 0.80),
            answerCView.heightAnchor.constraint(equalTo: self.answerCView.widthAnchor, multiplier: 28/120),
            answerCView.centerXAnchor.constraint(equalTo: self.cardView.centerXAnchor)
        ].forEach{$0.isActive = true}
        view.layoutIfNeeded()
        answerCView.layer.cornerRadius = answerCView.frame.size.height / 2
        buttonC.layer.cornerRadius = buttonA.frame.size.height / 2
        buttonC.layer.borderWidth = 1
        buttonC.layer.borderColor = UIColor.lightGray.cgColor
        answerCTextView.becomeFirstResponder()
    }
    
    func select(_ selectedButton: UIButton, _ answerView: UIView, _ answerTextView: UITextView) {
        if answerTextView.text != "Option" {
            answerView.layer.backgroundColor = green.cgColor
            answerTextView.textColor = UIColor.white
            selectedButton.layer.borderColor = UIColor.white.cgColor
            selectedButton.setTitleColor(.white, for: .normal)
            selectedAnswer = answerTextView.text
            selectedAnswerButton = selectedButton
            selectedAnswerView = answerView
            selectedAnswerTextView = answerTextView
        }
    }
    
    @IBAction func Answered(_ sender: UIButton) {
        resetAllAnswers()
        switch (sender.tag) {
            case 1:
                select(sender, answerAView, answerATextView)
            case 2:
                select(sender, answerBView, answerBTextView)
            case 3:
                select(sender, answerCView, answerCTextView)
            case 4:
                select(sender, answerDView, answerDTextView)
        default:
            return
        }
    }
    
    func resetAllAnswers() {
        let answerViews = [answerAView, answerBView, answerCView, answerDView]
        let answerTextViews = [answerATextView, answerBTextView, answerCTextView, answerDTextView]
        let buttons = [buttonA, buttonB, buttonC, buttonD]
        for button in buttons {
            button!.setTitleColor(red, for: .normal)
            button!.layer.borderWidth = 1
            button!.layer.borderColor = UIColor.lightGray.cgColor
        }
        for answerView in answerViews {
            for answerTextView in answerTextViews {
                if answerTextView!.text == "Option" {
                    answerTextView!.textColor = UIColor.lightGray
                } else {
                    answerTextView!.textColor = UIColor.black
                }
                answerView!.layer.backgroundColor = white.cgColor
            }
        }
    }

    @objc func leaderboardTapped(_ sender: UITapGestureRecognizer) {
        let name = AppEvents.Name("leaderboardTapped")
        AppEvents.logEvent(name)
        performSegue(withIdentifier: "goToLeaderboard", sender: self)
    }
    
    @objc func bitmojiTapped(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let goAction = UIAlertAction(title: "Yes", style: .destructive, handler: {
            (UIAlertAction) in
//            self.view.isUserInteractionEnabled = false
//            SVProgressHUD.show()
//            self.logout()
            self.performSegue(withIdentifier: "unwindToLogin", sender: self)
        })
        alert.addAction(cancelAction)
        alert.addAction(goAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func logout() {
        self.view.isUserInteractionEnabled = false
        SCSDKLoginClient.unlinkAllSessions(){ (success : Bool) in
            if success {
                print("logout")
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    SVProgressHUD.dismiss()
                    self.performSegue(withIdentifier: "unwindToLogin", sender: self)
                }
            }
        }
    }
    
    func setupAddButton() {
        let buttonFontSize = 12 * (view.frame.size.width / baseWidth)
        addButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: buttonFontSize)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(addButton)
        [
            addButton.topAnchor.constraint(equalTo: self.answerBView.bottomAnchor, constant: 15),
            addButton.bottomAnchor.constraint(equalTo: self.cardView.bottomAnchor, constant: -15),
            addButton.widthAnchor.constraint(equalTo: self.cardView.widthAnchor, multiplier: 0.2),
            addButton.heightAnchor.constraint(equalTo: self.addButton.widthAnchor, multiplier: 17/32),
            addButton.centerXAnchor.constraint(equalTo: self.cardView.centerXAnchor)
            ].forEach{$0.isActive = true}
        view.layoutIfNeeded()
        addButton.layer.cornerRadius = addButton.frame.size.height / 2
    }
    
    func setupClearButton() {
        let buttonFontSize = 12 * (view.frame.size.width / baseWidth)
        clearButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: buttonFontSize)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(clearButton)
        [
            clearButton.rightAnchor.constraint(equalTo: self.containerView.rightAnchor, constant: 0),
            clearButton.bottomAnchor.constraint(equalTo: self.cardView.topAnchor, constant: -10),
            clearButton.widthAnchor.constraint(equalTo: self.cardView.widthAnchor, multiplier: 0.2),
            clearButton.heightAnchor.constraint(equalTo: self.clearButton.widthAnchor, multiplier: 17/32),
            ].forEach{$0.isActive = true}
        view.layoutIfNeeded()
        clearButton.layer.cornerRadius = clearButton.frame.size.height / 2
    }
    
    @objc func shareTapped(_ sender: UITapGestureRecognizer) {
        let name = AppEvents.Name("shareSticker")
        AppEvents.logEvent(name)
        if selectedAnswer != nil {
            let answers = groupAnswers()
            create(answers)
        } else {
            let alert = UIAlertController(title: "Missing Correct Answer", message: "Please select the right answer by tapping A, B, C or D", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func fetchRandomQuestions() {
        let headers: HTTPHeaders = [
            "X-Api-Key": "EdUkRj2minaj28PJ1ULYS2bYLM5zJ3kO1yX94nCr",
        ]
        Alamofire.request(urlRandomQuestion, headers: headers).responseJSON { response in
            if response.result.isSuccess {
                let responseJSON = JSON(response.result.value!)
                self.questions = responseJSON["questions"].array!
            }
        }
    }
    
    func disable(_ tapGesture : UITapGestureRecognizer, _ view: UIView) {
        tapGesture.isEnabled = false
        view.alpha = 0.5
    }
    
    func setupTapGesture(tapGesture : UITapGestureRecognizer, view: UIView) {
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
    }
    
    func setupTapGesture(tapGesture : UITapGestureRecognizer, label: UILabel) {
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
    }
    
    func setupAllTextViews() {
        questionTextView.delegate = self
        questionTextView.isScrollEnabled = false
        textViewDidEndEditing(questionTextView)
        textViewDidChange(questionTextView)
        for answerTextView in answerTextViews {
            answerTextView.delegate = self
            answerTextView.isScrollEnabled = false
            textViewDidEndEditing(answerTextView)
            textViewDidChange(answerTextView)
        }
    }
    
    func setupAnswerFontSize() {
        let answerFontSize = 12 * (view.frame.size.width / baseWidth)
        for answerTextView in answerTextViews {
            answerTextView.font = answerATextView.font!.withSize(answerFontSize)
        }
    }
    
    func setupAnswerButtonFontSize() {
        let answerButtonFontSize = 15 * (view.frame.size.width / baseWidth)
        for answerButton in answerButtons {
            answerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: answerButtonFontSize)
        }
    }
    
    func setupAnswerButtonStyle() {
        for answerButton in answerButtons {
            answerButton.layer.cornerRadius = buttonA.frame.size.height / 2
            answerButton.layer.borderWidth = 1
            answerButton.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    
    func setupAnswerViewShape() {
        for answerView in answerViews {
            answerView.layer.cornerRadius = answerView.frame.size.height / 2
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchRandomQuestions()
        hideKeyboardWhenTappedAround()
        scrollView.showsVerticalScrollIndicator = false
        registerForPushNotifications()
        self.questionTextView.autocapitalizationType = .allCharacters
        answerTextViews = [answerATextView, answerBTextView, answerCTextView, answerDTextView]
        answerList = [answerATextView, answerBTextView]
        answerViews = [answerAView, answerBView, answerCView, answerDView]
        answerButtons = [buttonA, buttonB, buttonC, buttonD]
        
        //leaderboard button
        tapGesture1 = UITapGestureRecognizer(target: self, action: #selector(self.leaderboardTapped(_:)))
        setupTapGesture(tapGesture: tapGesture1, label: leaderboardLabel)
        
        //bitmoji button
        tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(self.bitmojiTapped(_:)))
        setupTapGesture(tapGesture: tapGesture2, view: bitmojiImageView)
        
        // share snap button
        tapGesture3 = UITapGestureRecognizer(target: self, action: #selector(self.shareTapped(_:)))
        setupTapGesture(tapGesture: tapGesture3, view: shareSnapView)
        disable(tapGesture3, shareSnapView)
        shareSnapView.layer.cornerRadius = 10 * (view.frame.size.width / baseWidth)
        
        // shuffle button
        tapGesture4 = UITapGestureRecognizer(target: self, action: #selector(self.didFetchRandomQuestion(_:)))
        setupTapGesture(tapGesture: tapGesture4, view: randomQuestionView)
        randomQuestionView.layer.cornerRadius = 10 * (view.frame.size.width / baseWidth)
        
        let fontSize = 14 * (view.frame.size.width / baseWidth)
        questionTextView.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        setupAllTextViews()
        setupAddButton()
        setupClearButton()
        setupAnswerButtonFontSize()
        setupAnswerButtonStyle()
        setupAnswerFontSize()
        setupAnswerViewShape()
        
        //card
        cardView.layer.cornerRadius = 20 * (view.frame.size.width / baseWidth)
        cardView.layer.masksToBounds = true
        
        // create temporary file
        temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFilename)
        
        //notification keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        snapAPI = SCSDKSnapAPI()
        setBitmojiImage()
    }
    
    func setBitmojiImage() {
        if UserDefaults.standard.string(forKey: "bitmojiUrl") != nil {
            bitmojiImageView.downloaded(from: UserDefaults.standard.string(forKey: "bitmojiUrl")!)
        } else {
            bitmojiImageView.image = UIImage(named: "profile.png")
        }
    }
    
    func groupAnswers() -> [String] {
        let answerTextViews = [answerATextView, answerBTextView, answerCTextView, answerDTextView]
        var answers : [String] = []
        for ansTextView in answerTextViews {
            if ansTextView!.text != "Option" {
                answers.append(ansTextView!.text)
            }
        }
        return answers
    }
    
    func create(_ answers: [String]) {
        let parameters: Parameters = [
            "quizz": [
                "question": questionTextView.text!,
                "answers": answers,
                "correctAnswer": selectedAnswer!
            ],
            "userId": UserDefaults.standard.string(forKey: "userId")!
        ]
        let headers: HTTPHeaders = [
            "X-Api-Key": "EdUkRj2minaj28PJ1ULYS2bYLM5zJ3kO1yX94nCr",
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            if response.result.isSuccess {
                let responseJSON = JSON(response.result.value!)
                let quizzId = responseJSON["quizzId"].stringValue
                let urlTo = responseJSON["url"].stringValue
                self.selectedAnswer = nil
                self.share(quizzId, urlTo)
            } else {
                let alert = UIAlertController(title: "Error", message: "Connection Issues", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Get a new empty card after sharing
    func clearCard() {
        swipeUpLabel.text = "Swipe up to answer"
        logo.layer.backgroundColor = white.cgColor
        selectedAnswer = nil
        answerList = [answerATextView, answerBTextView]
        questionTextView.text = ""
        for answer in answerTextViews {
            answer.text = ""
        }
        setupAllTextViews()
        if answerCView.isDescendant(of: cardView) && answerDView.isDescendant(of: cardView) {
            answerCView.removeFromSuperview()
            answerDView.removeFromSuperview()
            addButton.translatesAutoresizingMaskIntoConstraints = false
            setupAddButton()
        } else if answerCView.isDescendant(of: cardView) {
            answerCView.removeFromSuperview()
            if addButton.alpha == 0 {
                for constraint in addButton.superview!.constraints {
                    if constraint.firstAttribute == .top && constraint.firstItem?.tag == addButton.tag {
                        constraint.isActive = false
                    }
                }
                addButton.topAnchor.constraint(equalTo: self.answerBView.bottomAnchor, constant: 15).isActive = true
                addButton.alpha = 1
            } else {
                addButton.topAnchor.constraint(equalTo: self.answerBView.bottomAnchor, constant: 15).isActive = true
            }
        }
        if addButton.alpha == 0 {
            for constraint in addButton.superview!.constraints {
                if constraint.firstAttribute == .top && constraint.firstItem?.tag == addButton.tag {
                    constraint.constant = 15
                }
            }
            addButton.alpha = 1
        }
    }
    
    // Remove add button, clear button and add logo
    func setupQuizzCard() {
        clearButton.removeFromSuperview()
        if addButton.isDescendant(of: cardView) {
            addButton.alpha = 0
            for constraint in addButton.superview!.constraints {
                if constraint.firstAttribute == .top && constraint.firstItem?.tag == addButton.tag {
                    constraint.constant = -20
                }
            }
        }
        selectedAnswerButton!.setTitleColor(red, for: .normal)
        selectedAnswerButton!.layer.borderWidth = 1
        selectedAnswerButton!.layer.borderColor = UIColor.lightGray.cgColor
        selectedAnswerView!.layer.backgroundColor = white.cgColor
        selectedAnswerTextView!.textColor = UIColor.black
        logo.layer.backgroundColor = red.cgColor
        let fontSize = 12 * (view.frame.size.width / baseWidth)
        logo.font = logo.font.withSize(fontSize)
        logo.layer.backgroundColor = red.cgColor
        logo.layer.masksToBounds = true
        logo.layer.cornerRadius = 7 * (view.frame.size.width / baseWidth)
        swipeUpLabel.text = swipeUpLabel.text! + " 👆"
    }
    
    // share the actual card to snapchat
    func share(_ quizzId: String, _ urlTo: String) {
        view.isUserInteractionEnabled = false
        setupQuizzCard()
        let userId = UserDefaults.standard.string(forKey: "userId")!
        let snapContent = SCSDKNoSnapContent()
        let stickerImageUrl = png(with: containerView)
        let sticker = SCSDKSnapSticker(stickerUrl: stickerImageUrl!, isAnimated: false)
        snapContent.sticker = sticker
        snapContent.attachmentUrl = urlTo + "/\(userId)/\(quizzId)"
        snapAPI?.startSending(snapContent) { [weak self] (error: Error?) in
            self?.view.isUserInteractionEnabled = true
            
            self!.clearCard()
            self!.setupClearButton()
        }
    }
    
    // Create Png from a UIView
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
    
    @IBAction func unwindToQuizzBuilder(_ sender: UIStoryboardSegue) {}
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight + 50, right: 0)
            scrollView.scrollIndicatorInsets = scrollView.contentInset
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
}

extension QuizzBuilderViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        switch (textView.tag) {
            case 1:
                let size = CGSize(width: textView.frame.width, height: .infinity)
                let estimatedSize = textView.sizeThatFits(size)
                textView.constraints.forEach { (constraint) in
                    if constraint.firstAttribute == .height {
                        constraint.constant = estimatedSize.height
                    }
                }
                topView.constraints.forEach { (constraint) in
                    if constraint.firstAttribute == .height {
                        constraint.constant = estimatedSize.height + 30
                    }
                }
            case 2:
                let size = CGSize(width: textView.frame.width, height: .infinity)
                let estimatedSize = textView.sizeThatFits(size)
                textView.constraints.forEach { (constraint) in
                    if constraint.firstAttribute == .height {
                        constraint.constant = estimatedSize.height
                    }
                }
            default:
                return
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars < 75    // 75 Limit Value
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        selectedTextView = textView
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        var answerCount = 0
        switch (textView.tag) {
            case 1:
                if textView.text.isEmpty {
                    textView.text = "TYPE YOUR QUESTION"
                    textView.textColor = UIColor.lightGray
                }
            case 2:
                if textView.text.isEmpty {
                    textView.text = "Option"
                    textView.textColor = UIColor.lightGray
                    if selectedAnswerButton != nil && textView == selectedAnswerTextView {
                        selectedAnswerButton!.setTitleColor(red, for: .normal)
                        selectedAnswerButton!.layer.borderWidth = 1
                        selectedAnswerButton!.layer.borderColor = UIColor.lightGray.cgColor
                        selectedAnswerView!.layer.backgroundColor = white.cgColor
                        textView.text = "Option"
                        textView.textColor = UIColor.lightGray
                    }
                }
            default:
                return
        }
        for answer in answerList {
            if answer.text != "Option" && answer.text != nil && answer.text != "" {
                answerCount += 1
            }
        }
        if answerCount == answerList.count && questionTextView.text != "TYPE YOUR QUESTION" {
            tapGesture3.isEnabled = true
            shareSnapView.alpha = 1
        } else {
            answerCount = 0
            disable(tapGesture3, shareSnapView)
        }
    }
}

extension QuizzBuilderViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}
