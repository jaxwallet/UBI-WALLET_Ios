// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit
import Kingfisher

struct ApprecationViewModel {
    let valueAttributedString: NSAttributedString
    let icon: UIImage?
    let backgroundColor: UIColor

    init(icon: UIImage?, valueAttributedString: NSAttributedString, backgroundColor: UIColor) {
        self.valueAttributedString = valueAttributedString
        self.icon = icon
        self.backgroundColor = backgroundColor
    }
}

class ApprecationView: UIView {

    private let valueLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)

        return view
    }()

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    init(edgeInsets: UIEdgeInsets = .init(top: 0, left: 2, bottom: 0, right: 2), spacing: CGFloat = 4) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false

        let stackView = [iconView, valueLabel].asStackView(spacing: spacing, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 9),
            iconView.heightAnchor.constraint(equalToConstant: 9),

            stackView.anchorsConstraint(to: self, edgeInsets: edgeInsets)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(viewModel: ApprecationViewModel) {
        valueLabel.attributedText = viewModel.valueAttributedString
        iconView.image = viewModel.icon
        iconView.isHidden = true
        backgroundColor = Colors.clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 2.0
    }
}

class EthTokenViewCell: UITableViewCell {
    private let background = UIView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let networkNameLabel = UILabel()
    private let apprecation24hoursView = ApprecationView()
    private let priceChangeLabel = UILabel()
    private let fiatValueLabel = UILabel()
    private let cryptoValueLabel = UILabel()
    private var viewsWithContent: [UIView] {
        [symbolLabel, apprecation24hoursView, priceChangeLabel]
    }

    private lazy var changeValueContainer: UIView = [priceChangeLabel, apprecation24hoursView].asStackView(spacing: 5)

    private var tokenIconImageView: TokenImageView = {
        let imageView = TokenImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var blockChainTagLabel = BlockchainTagLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false
        priceChangeLabel.textAlignment = .center
        fiatValueLabel.textAlignment = .center
        fiatValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        fiatValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let col0 = tokenIconImageView
        let row1 = [UIView.spacerWidth(flexible: true), changeValueContainer, blockChainTagLabel].asStackView(spacing: 5, alignment: .center)
        let col1 = [
            [symbolLabel, UIView.spacerWidth(flexible: true), cryptoValueLabel].asStackView(spacing: 5),
            UIView.spacer(height: 2),
            [nameLabel, UIView.spacerWidth(flexible: true), fiatValueLabel].asStackView(alignment: .center),
            UIView.spacer(height: 4),
            row1
        ].asStackView(axis: .vertical)
        let stackView = [col0, col1].asStackView(spacing: 12, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stackView)

        NSLayoutConstraint.activate([
            tokenIconImageView.heightAnchor.constraint(equalToConstant: 40),
            tokenIconImageView.widthAnchor.constraint(equalToConstant: 40),
            row1.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            stackView.anchorsConstraint(to: background, edgeInsets: .init(top: 12, left: 20, bottom: 16, right: 12)),
            tokenIconImageView.widthAnchor.constraint(equalToConstant: 40),

            background.topAnchor.constraint(equalTo: contentView.topAnchor),
            background.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            background.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func configure(viewModel: EthTokenViewCellViewModel) {
        selectionStyle = .none

        backgroundColor = Colors.appBackground
        background.backgroundColor = Colors.appWhite
        contentView.backgroundColor = Colors.appBackground
        background.cornerRadius = 8
        background.layer.shadowColor = Colors.lightGray.cgColor
        background.layer.shadowRadius = 2
        background.layer.shadowOffset = .zero
        background.layer.shadowOpacity = 0.6
        
        nameLabel.attributedText = viewModel.nameAttributedString
        nameLabel.baselineAdjustment = .alignCenters
        symbolLabel.attributedText = viewModel.symbolAttributedString
        symbolLabel.baselineAdjustment = .alignCenters
        networkNameLabel.attributedText = viewModel.networkNameAttributedString
        networkNameLabel.baselineAdjustment = .alignCenters

        cryptoValueLabel.attributedText = viewModel.cryptoValueAttributedString
        cryptoValueLabel.baselineAdjustment = .alignCenters

        apprecation24hoursView.configure(viewModel: viewModel.apprecationViewModel)

        priceChangeLabel.attributedText = viewModel.priceChangeUSDValueAttributedString

        fiatValueLabel.attributedText = viewModel.fiatValueAttributedString

        viewsWithContent.forEach {
            $0.alpha = viewModel.alpha
        }
        tokenIconImageView.subscribable = viewModel.iconImage

        blockChainTagLabel.configure(viewModel: viewModel.blockChainTagViewModel)
        changeValueContainer.isHidden = !viewModel.blockChainTagViewModel.blockChainNameLabelHidden
    }
}
