//
//  PromptPendingKycViewModel.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import UIKit

struct PromptPendingKycViewModel: PromptKycViewModel {
    let walletAddress: AlphaWallet.Address

    var backgroundColor: UIColor {
        return UIColor(hex: "FFC107")
    }
 
    var title: String {
        return R.string.localizable.kycPendingPromptTitle()
    }

    var description: String {
        return R.string.localizable.kycPendingPromptDescription()
    }

    var backupButtonBackgroundColor: UIColor {
        return UIColor.clear
    }
    
    var backupButtonTitle: String {
        return R.string.localizable.kycPendingPromptActionButtonTitle()
    }
}
