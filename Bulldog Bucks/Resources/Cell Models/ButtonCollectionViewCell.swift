//
//  ButtonCollectionViewCell.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 9/4/17.
//
//

import UIKit
import MBProgressHUD

class ButtonCollectionViewCell: UICollectionViewCell {
    
    public static let reuseIdentifier = "ButtonCollectionViewCell"
    
    @IBOutlet weak var logoutView: UIView!
    @IBOutlet weak var switchOutlet: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    
    
	@IBAction func switchToggled() {
        print("Switch Toggled")
        var status: CardState!
        if switchOutlet.isOn {
            status = CardState.active
        } else {
            status = CardState.frozen
        }
        if let toggleCardStatusAction = toggleCardStatusAction {
            MBProgressHUD.showAdded(to: self, animated: true)
            toggleCardStatusAction(status) { (success) in
                if success {
                    if self.switchOutlet.isOn {
                        self.statusLabel.text = "ZAGCARD Active"
                    } else {
                        self.statusLabel.text = "ZAGCARD Frozen"
                    }
                } else {
                    print("Toggling Status Failed")
                    // Revert Switch on Failure
                    self.switchOutlet.setOn(!self.switchOutlet.isOn, animated: true)
                }
                MBProgressHUD.hide(for: self, animated: true)
            }
        }
		
	}
    var logoutAction: (() -> Void)?
    var toggleCardStatusAction: ((CardState, @escaping((Bool) -> Void)) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(logoutTapped(sender:)))
        logoutView.addGestureRecognizer(tap)
    }
    
    func logoutTapped(sender: UITapGestureRecognizer) {
        print("logout tapped")
        if let logoutAction = logoutAction {
            logoutAction()
        }
    }
    
    
}
