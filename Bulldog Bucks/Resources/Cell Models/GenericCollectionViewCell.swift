//
//  CollectionViewCell.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 9/4/17.
//
//

import UIKit

class GenericCollectionViewCell: UICollectionViewCell {
    
    public static let reuseIdentifier = "GenericCollectionViewCell"
    
    @IBOutlet weak var amountLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
