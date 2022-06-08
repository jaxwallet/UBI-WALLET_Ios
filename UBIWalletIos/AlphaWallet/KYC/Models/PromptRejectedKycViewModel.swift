//
//  PromptRejectedKycViewModel.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import UIKit

struct PromptRejectedKycViewModel: PromptKycViewModel {
    let walletAddress: AlphaWallet.Address

    var backgroundColor: UIColor {
        return UIColor(hex: "FE4443")
    }
 
    var title: String {
        return R.string.localizable.kycRejectedPromptTitle()
    }

    var description: String {
        return R.string.localizable.kycRejectedPromptDescription()
    }

    var backupButtonBackgroundColor: UIColor {
        return UIColor.clear
    }
    
    var backupButtonTitle: String {
        return R.string.localizable.kycRejectedPromptActionButtonTitle()
    }
}
