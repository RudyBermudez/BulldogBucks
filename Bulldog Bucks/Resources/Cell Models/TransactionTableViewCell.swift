//
//  TransactionTableViewCell.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 9/4/17.
//
//

import UIKit

class TransactionTableViewCell: UITableViewCell {

    @IBOutlet weak var venueLabel: UILabel!
    
    @IBOutlet weak var amountLabel: UILabel!
    
    public static let storyboardIdentifier = "transactionCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
