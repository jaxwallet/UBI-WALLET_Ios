//
//  PromptUnapprovedKycViewModel.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import UIKit

struct PromptUnapprovedKycViewModel: PromptKycViewModel {
    let walletAddress: AlphaWallet.Address

    var backgroundColor: UIColor {
        return UIColor(hex: "FFC107")
    }
 
    var title: String {
        return R.string.localizable.kycUnapprovedPromptTitle()
    }

    var description: String {
        return R.string.localizable.kycUnapprovedPromptDescription()
    }

    var backupButtonBackgroundColor: UIColor {
        return UIColor.clear
    }
    
    var backupButtonTitle: String {
        return R.string.localizable.kycUnapprovedPromptActionButtonTitle()
    }
}
