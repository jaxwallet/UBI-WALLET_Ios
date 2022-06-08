//
//  PromptKycView.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import UIKit

protocol PromptKycViewDelegate: AnyObject {
    func didChooseVerify(inView view: PromptKycView)
}

class PromptKycView: UIView {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let remindMeLaterButton = UIButton(type: .system)
    private let viewModel: PromptKycViewModel

    weak var delegate: PromptKycViewDelegate?

    init(viewModel: PromptKycViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        actionButton.addTarget(self, action: #selector(verify), for: .touchUpInside)
        actionButton.setContentHuggingPriority(.required, for: .horizontal)

        let row0 = [titleLabel].asStackView(axis: .horizontal, spacing: 20, alignment: .top)
        let stackView = [
            row0,
            UIView.spacer(height: 10),
            descriptionLabel,
            UIView.spacer(height: 10),
            actionButton,
        ].asStackView(axis: .vertical, alignment: .leading)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            row0.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            row0.heightAnchor.constraint(equalToConstant: 30),
//            descriptionLabel.widthAnchor.constraint(equalTo: actionButton.widthAnchor, constant: 30),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        backgroundColor = viewModel.backgroundColor
        cornerRadius = Metrics.CornerRadius.backUp
        borderColor = Colors.black
        borderWidth = 0

        titleLabel.font = viewModel.titleFont
        titleLabel.numberOfLines = 3
        titleLabel.textColor = viewModel.titleColor
        titleLabel.text = viewModel.title
        
        if viewModel.title.lowercased() == "pending" {
            actionButton.isHidden = true
        }
        //For small screens
        titleLabel.adjustsFontSizeToFitWidth = true

        remindMeLaterButton.setImage(viewModel.moreButtonImage, for: .normal)
        remindMeLaterButton.tintColor = viewModel.moreButtonColor

        descriptionLabel.font = viewModel.descriptionFont
        descriptionLabel.textColor = viewModel.descriptionColor
        descriptionLabel.text = viewModel.description
        descriptionLabel.numberOfLines = 0

        actionButton.tintColor = viewModel.backupButtonTitleColor
        actionButton.titleLabel?.font = viewModel.backupButtonTitleFont
        actionButton.setBackgroundColor(viewModel.backupButtonBackgroundColor, forState: .normal)
        actionButton.setTitleColor(viewModel.backupButtonTitleColor, for: .normal)
        actionButton.setTitle(viewModel.backupButtonTitle, for: .normal)
        actionButton.setImage(viewModel.backupButtonImage, for: .normal)
        actionButton.contentEdgeInsets = viewModel.backupButtonContentEdgeInsets
        actionButton.borderColor = Colors.appWhite
        actionButton.cornerRadius = 5
        actionButton.borderWidth = 2
        swapButtonTextAndImage(actionButton)
    }

    @objc private func verify() {
        delegate?.didChooseVerify(inView: self)
    }

    private func swapButtonTextAndImage(_ button: UIButton) {
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
}
