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
	var delegate: LoginViewControllerDelegate?
	
	lazy var notificationCenter: NotificationCenter = {
		return NotificationCenter.default
	}()
	
	var savedUsername: String!
	var savedPassword: String!
	
	let client = APIClient()
	
	// MARK: - UIViewController
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let username = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "username"), let password = UserDefaults(suiteName: "group.bdbMeter")!.string(forKey: "password") {
			self.savedUsername = username
			self.savedPassword = password
		}
		
		// Notification Center Observers
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillAppear(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		notificationCenter.addObserver(self, selector: #selector(self.keyboardWillDisappear(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
		
		
		// Keyboard Dismissal 
		let tapper = UITapGestureRecognizer(target: view, action:#selector(UIView.endEditing))
		tapper.cancelsTouchesInView = false
		view.addGestureRecognizer(tapper)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Login Action Methods
	
	@IBAction func Login(_ sender: UIButton) {
		if Reachability.isConnectedToNetwork() {
			loginButton.startLoadingAnimation()
			guard let userIDTextFieldText = userIDTextField.text, let userPinTextFieldText = userPinTextField.text else {
				loginButton.setOriginalState()
				return
			}
			if userIDTextFieldText.isEmpty || userPinTextFieldText.isEmpty {
				//TODO: Show alert
				loginButton.setOriginalState()
				return
			} else {
				checkCredentials(withUsername: userIDTextFieldText, withPin: userPinTextFieldText)
			}
		} else {
			showAlert(target: self, title: "No Active Connection to Internet")
		}
	}
	
	// MARK: - Keyboard Methods
	
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
	
	func keyboardWillDisappear(notification: NSNotification){
		UIView.animate(withDuration: 0.5) {
			self.loginButtonBottomConstraint.constant = 202.0
			self.view.layoutIfNeeded()
		}
	}
	
	func checkCredentials(withUsername: String, withPin: String) {
		client.authenticate(withStudentID: withUsername, withPIN: withPin).then { (_) -> Void in
			self.savedUsername = withUsername
			self.savedPassword = withPin
			UserDefaults(suiteName: "group.bdbMeter")!.set(self.savedUsername, forKey: "username")
			UserDefaults(suiteName: "group.bdbMeter")!.set(self.savedPassword, forKey: "password")
			self.loginButton.startFinishAnimation {
				self.delegate?.didLoginSuccessfully()
			}
			
		}.catch { (error) in
			if let error = error as? ClientError {
				self.loginButton.setOriginalState()
				showAlert(target: self, title: error.domain())
			}
			print(error)
			UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "username")
			UserDefaults(suiteName: "group.bdbMeter")!.set(nil, forKey: "password")
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
