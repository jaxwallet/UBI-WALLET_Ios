// Copyright © 2019 Stormbird PTE. LTD.

import UIKit
import LocalAuthentication

protocol VerifySeedPhraseViewControllerDelegate: AnyObject {
    var contextToVerifySeedPhrase: LAContext { get }
    var isInactiveBecauseWeAccessingBiometrics: Bool { get set }

    func didVerifySeedPhraseSuccessfully(for account: AlphaWallet.Address, in viewController: VerifySeedPhraseViewController)
    func biometricsFailed(for account: AlphaWallet.Address, inViewController viewController: VerifySeedPhraseViewController)
}

class VerifySeedPhraseViewController: UIViewController {
    private enum State {
        case editingSeedPhrase(words: [String])
        case seedPhraseNotMatched(words: [String])
        case seedPhraseMatched(words: [String])
        case keystoreError(KeystoreError)
        case notDisplayedSeedPhrase
        case errorDisplaySeedPhrase(KeystoreError)

        var words: [String] {
            switch self {
            case .editingSeedPhrase(let words), .seedPhraseMatched(let words), .seedPhraseNotMatched(let words):
                return words
            case .keystoreError, .notDisplayedSeedPhrase, .errorDisplaySeedPhrase:
                return .init()
            }
        }
    }

    private var viewModel: VerifySeedPhraseViewModel
    private let keystore: Keystore
    private let account: AlphaWallet.Address
    private let analyticsCoordinator: AnalyticsCoordinator
    private let roundedBackground = RoundedBackground()
    private let subtitleLabel = UILabel()
    private let seedPhraseTextView = UITextView()
    private let seedPhraseCollectionView: SeedPhraseCollectionView = {
        let collectionView = SeedPhraseCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    private let errorLabel = UILabel()
    private lazy var clearChooseSeedPhraseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearChosenSeedPhrases), for: .touchUpInside)
        button.setTitle(R.string.localizable.clearButtonTitle(), for: .normal)
        button.setTitleColor(Colors.headerThemeColor, for: .normal)
        button.titleLabel?.font = viewModel.importKeystoreJsonButtonFont
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.contentHorizontalAlignment = .right
        return button
    }()
    
    private var viewWhiteCenter: UIView = {
       let view = UIView()
        view.backgroundColor = Colors.appWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cornerRadius = 5
        return view
    }()
    
    private let buttonsBar = ButtonsBar(configuration: .green(buttons: 1))
    private var state: State {
        didSet {
            switch state {
            case .editingSeedPhrase(let words):
                seedPhraseCollectionView.viewModel = .init(words: words, isSelectable: true)
                clearError()
            case .seedPhraseMatched(let words):
                seedPhraseCollectionView.viewModel = .init(words: words, isSelectable: true)
                errorLabel.text = viewModel.noErrorText
                errorLabel.textColor = viewModel.noErrorColor
                delegate?.didVerifySeedPhraseSuccessfully(for: account, in: self)
            case .seedPhraseNotMatched:
                errorLabel.text = R.string.localizable.walletsVerifySeedPhraseWrong()
                errorLabel.textColor = viewModel.errorColor
            case .keystoreError(let error):
                seedPhraseCollectionView.viewModel = .init(words: [], isSelectable: true)
                errorLabel.text = error.errorDescription
                errorLabel.textColor = viewModel.errorColor
            case .notDisplayedSeedPhrase:
                seedPhraseCollectionView.viewModel = .init(words: [], isSelectable: true)
                clearChooseSeedPhraseButton.isHidden = true
                continueButton.isEnabled = false
            case .errorDisplaySeedPhrase(let error):
                seedPhraseCollectionView.viewModel = .init(words: [], isSelectable: true)
                errorLabel.text = error.errorDescription
                errorLabel.textColor = viewModel.errorColor
            }
        }
    }
    private var notDisplayingSeedPhrase: Bool {
        switch state {
        case .editingSeedPhrase:
            return false
        case .seedPhraseMatched:
            return false
        case .seedPhraseNotMatched:
            return false
        case .keystoreError:
            return false
        case .notDisplayedSeedPhrase:
            return true
        case .errorDisplaySeedPhrase:
            return false
        }

    }
    private var continueButton: UIButton {
        return buttonsBar.buttons[0]
    }
    
    private let selectedSeedPhraseCollectionView: SeedPhraseCollectionView = {
        let collectionView = SeedPhraseCollectionView()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = Colors.clear
        return collectionView
    }()

    weak var delegate: VerifySeedPhraseViewControllerDelegate?

    init(keystore: Keystore, account: AlphaWallet.Address, analyticsCoordinator: AnalyticsCoordinator) {
        self.keystore = keystore
        self.account = account
        self.analyticsCoordinator = analyticsCoordinator
        self.viewModel = .init()
        self.state = .notDisplayedSeedPhrase
        super.init(nibName: nil, bundle: nil)

        seedPhraseCollectionView.bounces = true
        seedPhraseCollectionView.seedPhraseDelegate = self

        let stackView = [
            UIView.spacer(height: ScreenChecker().isNarrowScreen ? 20: 30),
            subtitleLabel,
        ].asStackView(axis: .vertical)
        
        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)
        roundedBackground.addSubview(stackView)
        roundedBackground.addSubview(viewWhiteCenter)
        viewWhiteCenter.addSubview(selectedSeedPhraseCollectionView)
        roundedBackground.addSubview(seedPhraseCollectionView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        clearChooseSeedPhraseButton.isHidden = true

        roundedBackground.addSubview(clearChooseSeedPhraseButton)
        roundedBackground.backgroundColor = Colors.appBackground

        continueButton.isEnabled = false

        let footerBar = UIView()
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        footerBar.backgroundColor = .clear
        roundedBackground.addSubview(footerBar)

        footerBar.addSubview(buttonsBar)

        NSLayoutConstraint.activate([

            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),

            viewWhiteCenter.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            viewWhiteCenter.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            viewWhiteCenter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            selectedSeedPhraseCollectionView.leadingAnchor.constraint(equalTo: viewWhiteCenter.leadingAnchor, constant: 16),
            selectedSeedPhraseCollectionView.trailingAnchor.constraint(equalTo: viewWhiteCenter.trailingAnchor, constant: -16),
            selectedSeedPhraseCollectionView.topAnchor.constraint(equalTo: viewWhiteCenter.topAnchor, constant: 16),
            selectedSeedPhraseCollectionView.bottomAnchor.constraint(equalTo: viewWhiteCenter.bottomAnchor, constant: -16),
            selectedSeedPhraseCollectionView.heightAnchor.constraint(equalToConstant: ScreenChecker().isNarrowScreen ? 135 : 125),

            seedPhraseCollectionView.topAnchor.constraint(equalTo: viewWhiteCenter.bottomAnchor, constant: 37),
            seedPhraseCollectionView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            seedPhraseCollectionView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            seedPhraseCollectionView.heightAnchor.constraint(equalToConstant: 160),

            clearChooseSeedPhraseButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            clearChooseSeedPhraseButton.topAnchor.constraint(equalTo: viewWhiteCenter.topAnchor, constant: -40),

            buttonsBar.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            buttonsBar.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            buttonsBar.topAnchor.constraint(equalTo: footerBar.topAnchor),
            buttonsBar.heightAnchor.constraint(equalToConstant: ButtonsBar.buttonsHeight),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ButtonsBar.buttonsHeight - ButtonsBar.marginAtBottomScreen),
            footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            roundedBackground.createConstraintsWithContainer(view: view),
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTakeScreenShot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            return
        }
        removeSeedPhraseFromDisplay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSeedPhrases()
    }

    @objc private func appDidBecomeActive() {
        showSeedPhrases()
    }

    @objc private func didTakeScreenShot() {
        displaySuccess(message: R.string.localizable.walletsVerifySeedPhraseDoNotTakeScreenshotDescription())
    }

    private func showSeedPhrases() {
        guard isTopViewController else { return }
        guard notDisplayingSeedPhrase else { return }
        guard let context = delegate?.contextToVerifySeedPhrase else { return }
        keystore.exportSeedPhraseOfHdWallet(forAccount: account, context: context, reason: .prepareForVerification) { result in
            switch result {
            case .success(let words):
                self.state = .editingSeedPhrase(words: words.split(separator: " ").map { String($0) }.shuffled())
            case .failure(let error):
                self.state = .errorDisplaySeedPhrase(error)
                self.delegate?.biometricsFailed(for: self.account, inViewController: self)
            }
        }
    }

    func configure() {
        view.backgroundColor = Colors.appBackground

        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = viewModel.subtitleColor
        subtitleLabel.font = viewModel.subtitleFont
        //Important for smaller screens
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = viewModel.title

        errorLabel.textColor = viewModel.noErrorColor
        errorLabel.text = viewModel.noErrorText
        errorLabel.font = viewModel.errorFont
        errorLabel.numberOfLines = 0
        
        seedPhraseCollectionView.configure()

        buttonsBar.configure()
        continueButton.setTitle(R.string.localizable.walletsVerifySeedPhraseVerify(), for: .normal)
        continueButton.addTarget(self, action: #selector(verify), for: .touchUpInside)
    }
    
    @objc func verify() {
        guard let context = delegate?.contextToVerifySeedPhrase else { return }
        keystore.verifySeedPhraseOfHdWallet(seedPhraseTextView.text.lowercased().trimmed, forAccount: account, context: context) { result in
            switch result {
            case .success(let isMatched):
                //Safety precaution, we clear the seed phrase. The next screen may be the prompt to elevate security of wallet screen which the user can go back from
                self.clearChosenSeedPhrases()
                self.updateStateWithVerificationResult(isMatched)
            case .failure(let error):
                self.reflectError(error)
                self.delegate?.biometricsFailed(for: self.account, inViewController: self)
            }
        }
    }

    @objc func clearChosenSeedPhrases() {
        seedPhraseTextView.text = ""
        seedPhraseCollectionView.viewModel.clearSelectedWords()
        clearChooseSeedPhraseButton.isHidden = true
        continueButton.isEnabled = false
        state = .editingSeedPhrase(words: state.words)
        selectedSeedPhraseCollectionView.viewModel = .init(words: [], isSelectable: false)
        selectedSeedPhraseCollectionView.configure()
    }

    private func updateStateWithVerificationResult(_ isMatched: Bool) {
        if isMatched {
            state = .seedPhraseMatched(words: state.words)
        } else {
            state = .seedPhraseNotMatched(words: state.words)
        }
    }

    private func reflectError(_ error: KeystoreError) {
        state = .keystoreError(error)
    }

    func removeSeedPhraseFromDisplay() {
        state = .notDisplayedSeedPhrase
    }

    private func clearError() {
        errorLabel.text = viewModel.noErrorText
        errorLabel.textColor = viewModel.noErrorColor
    }
}

extension VerifySeedPhraseViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            verify()
            return false
        } else {
            state = .editingSeedPhrase(words: state.words)
            return true
        }
    }

}

extension VerifySeedPhraseViewController: SeedPhraseCollectionViewDelegate {
    func didTap(word: String, atIndex index: Int, inCollectionView collectionView: SeedPhraseCollectionView) {
        if seedPhraseTextView.text.isEmpty {
            seedPhraseTextView.text += word
        } else {
            seedPhraseTextView.text += " \(word)"
        }
        clearError()
        if collectionView.viewModel.isEveryWordSelected {
            //Deliberately hide the Clear button after user has chosen all the words, as they are likely to want to verify now and we don't want them to accidentally hit the Clear button
            clearChooseSeedPhraseButton.isHidden = true
            continueButton.isEnabled = true
        } else {
            clearChooseSeedPhraseButton.isHidden = false
            continueButton.isEnabled = false
        }
        
        let selectedWords : [String] = seedPhraseTextView.text.components(separatedBy: " ")
            
        selectedSeedPhraseCollectionView.viewModel = .init(words: selectedWords, isSelectable: false)
        selectedSeedPhraseCollectionView.configure()
    }
}
