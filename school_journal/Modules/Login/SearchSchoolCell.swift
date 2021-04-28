//
//  SerchSchoolCell.swift
//  scool_journal
//
//  Created by отмеченные on 13/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit

class SearchSchoolCell: UITableViewCell, HasNib, Reusable {

    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbLocation: UILabel!

    @IBOutlet weak var lbDomain: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
