//
//  ViewController.swift
//  Bulldog Bucks Meter
//
//  Created by Rudy Bermudez on 9/26/16.
//
//

import UIKit


protocol LoginViewControllerDelegate {
	func didLoginSuccessfully()
}

class LoginViewController: UIViewController, UIViewControllerTransitioningDelegate{

	// MARK: - IBOutlets
	@IBOutlet weak var loginButtonBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var userIDTextField: UITextField!
	@IBOutlet weak var userPinTextField: UITextField!
	@IBOutlet weak var loginButton: TKTransitionSubmitButton!
    
	
	// MARK: - Properties
    
    /**
     The number of times `ClientError.invalidCredentials` occurs.
     
     - Note: Unfortunately, due to the poor Zagweb website. It is normal for the website to redirect the connection to another url the first time the user connects, for that reason, if there is a saved username and password; the invalidCredentials error will only be shown when there are 2 or more failed attempts.
     */
    var failedAttempts = 0
    
	var delegate: LoginViewControllerDelegate?
	
	lazy var notificationCenter: NotificationCenter = {
		return NotificationCenter.default
	}()
	
    /// User's Student ID as a String
	var savedStudentID: String!
    
    /// User's PIN as a String. Set in
	var savedPIN: String!
	
    /// Class Instance of ZagwebClient
	let client = ZagwebClient()
	
    
	// MARK: - UIViewController
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupNotificationCenter()
        setupGestureRecognizer()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
    /**
     Login Action
     
     Checks if there is internet connection, checks to make sure fields are not empty, then attempts to authenticate by calling `self.login()`
     
     - Parameter sender: The instance of UIButton that sends the action
     */

	@IBAction func loginAction(_ sender: Any) {
        if isConnectedToNetwork() {
            guard let userIDTextFieldText = userIDTextField.text, let userPinTextFieldText = userPinTextField.text else {
                return
            }
            if userIDTextFieldText.isEmpty || userPinTextFieldText.isEmpty {
                showAlert(target: self, title: "Error", message: "Student ID and PIN cannot be left empty")
                return
            } else {
                self.loginButton.startLoadingAnimation()
                self.savedStudentID = userIDTextFieldText
                self.savedPIN = userPinTextFieldText
                login()
            }
        } else {
            showAlert(target: self, title: "No Active Connection to Internet")
        }
	}
    
    /**
     Login Action
     
     Checks if there is internet connection, then attempts to authenticate by calling `self.checkCredentials()`
     
     */
    func login() {
        if isConnectedToNetwork() {
            checkCredentials(withStudentID: savedStudentID, withPIN: savedPIN)
        } else {
            showAlert(target: self, title: "No Active Connection to Internet")
        }
    }
	
    // MARK: - UI Helper Functions
    
    /**
     Adds NotificationCenter Observers for when the Keyboard Appears and Disappears. 
     - When keyboard appears, `self.keyboardWillAppear()` is called
     - When keyboard disappers, `self.keyboardWillDisappear()` is called
     */
    func setupNotificationCenter() {
        // Notification Center Observers
        notificationCenter.addObserver(self, selector: #selector(self.keyboardWillAppear(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.keyboardWillDisappear(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
	
    /**
     Adds a UITapGestureRecognizer to see if the user taps outside of the text field.
     
     If a tap is recognized, `UIView.endEditing` is called
    */
    func setupGestureRecognizer() {
        // Keyboard Dismissal
        let tapper = UITapGestureRecognizer(target: view, action:#selector(UIView.endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
    }
    
    /**
     Animation that moves the `loginButtonBottomConstraint` 20 points higher than the top of the keyboard frame.
     
     Called when notification is posted for `NSNotification.Name.UIKeyboardWillShow`
     */
	func keyboardWillAppear(notification: NSNotification){
		if let userInfoDict = notification.userInfo, let keyboardFrameValue = userInfoDict[UIKeyboardFrameEndUserInfoKey] as? NSValue {
			let keyboardFrame = keyboardFrameValue.cgRectValue
			
			UIView.animate(withDuration: 0.8) {
				self.loginButtonBottomConstraint.constant = keyboardFrame.size.height
					+ 20
				self.view.layoutIfNeeded()
			}
			
		}
	}
	
    /**
     Animation that moves the loginButtonBottomConstraint to it's original position.
     
     Called when notification is posted for `NSNotification.Name.UIKeyboardDidHide`
     */
	func keyboardWillDisappear(notification: NSNotification){
		UIView.animate(withDuration: 0.5) {
			self.loginButtonBottomConstraint.constant = 202.0
			self.view.layoutIfNeeded()
		}
	}
	
    /**
     Checks to see if the authentication to Zagweb is successful. If successful, `delegate?.didLoginSuccessfully()` is called and transitions to `ViewController`. If fails, shows alert.
     
     - Parameters:
        - withStudentID: The student ID of the user as a `String`
        - withPIN: The PIN of the user as a `String`
     */
	func checkCredentials(withStudentID: String, withPIN: String) {
		client.authenticate(withStudentID: withStudentID, withPIN: withPIN).then { (_) -> Void in
            self.failedAttempts = 0
            self.savedStudentID = withStudentID
            self.savedPIN = withPIN
			UserDefaults(suiteName: "group.bdbMeter")!.set(self.savedStudentID, forKey: "studentID")
			UserDefaults(suiteName: "group.bdbMeter")!.set(self.savedPIN, forKey: "PIN")
			self.loginButton.startFinishAnimation {
				self.delegate?.didLoginSuccessfully()
			}
			
		}.catch { (error) in
			if let error = error as? ClientError {
                switch error {
                case .invalidCredentials:
                    self.failedAttempts += 1
                    if self.failedAttempts > 1 {
                        self.loginButton.returnToOriginalState()
                        showAlert(target: self, title: error.domain())
                    } else {
                        self.login()
                    }
                default:
                    self.loginButton.returnToOriginalState()
                    showAlert(target: self, title: error.domain())
                }
				
			}
			UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "studentID")
			UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "PIN")
		}
	}
	
	// MARK: - UIViewControllerTransitioningDelegate
	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		let fadeInAnimator = TKFadeInAnimator()
		return fadeInAnimator
	}
	
	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return nil
	}
	
	
}
