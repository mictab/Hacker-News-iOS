//
//  StoryTableViewCell.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/7/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import UIKit

class StoryTableViewCell: UITableViewCell {

    
    // MARK: Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
