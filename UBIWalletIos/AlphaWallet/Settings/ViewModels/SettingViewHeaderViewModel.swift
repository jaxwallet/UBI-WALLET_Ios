//
//  SettingViewHeaderViewModel.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 02.06.2020.
//

import UIKit

struct SettingViewHeaderViewModel {
    let titleText: String
    var detailsText: String?
    var titleTextFont: UIFont
    var showTopSeparator: Bool = false

    var titleTextColor: UIColor {
        return Colors.appText
    }

    var detailsTextColor: UIColor {
        return Colors.appText
    }
    var detailsTextFont: UIFont {
        return Fonts.regular(size: 13)
    }

    var backgroundColor: UIColor {
        return Colors.settingsBackGroundColor
    }

    var separatorColor: UIColor {
        return Colors.settingsSeperatorColor
    }
}

extension SettingViewHeaderViewModel {
    init(section: SettingsSection) {
        titleText = section.title
        switch section {
        case .tokenStandard(let value), .version(let value):
            detailsText = value
            titleTextFont = Fonts.regular(size: 15)
            if case .tokenStandard = section {
                showTopSeparator = false
            }
        case .wallet, .system, .help:
            titleTextFont = Fonts.semibold(size: 15)
        }
    }
}
