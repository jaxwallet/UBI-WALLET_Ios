//
//  PromptKycCoordinator.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import UIKit
import Alamofire
import PromiseKit

protocol PromptKycCoordinatorProminentPromptDelegate: AnyObject {

    func updatePrompt(inCoordinator coordinator: PromptKycCoordinator)
    func startVerification(_ url: URL)
}

protocol PromptKycCoordinatorSubtlePromptDelegate: AnyObject {
    func updatePrompt(inCoordinator coordinator: PromptKycCoordinator)
}

protocol PromptKycCoordinatorUpdateTabDelegate: AnyObject {
    func changeVerifyToCollectTab()
    func changeCollectToVerifyTab()
}

class PromptKycCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    
    var prominentPromptView: UIView?
    var subtlePromptView: UIView?
    
    weak var prominentPromptDelegate: PromptKycCoordinatorProminentPromptDelegate?
    weak var subtlePromptDelegate: PromptKycCoordinatorSubtlePromptDelegate?
    weak var updateTabDelegate: PromptKycCoordinatorUpdateTabDelegate?
    
    private let wallet: Wallet
    
    private func readState() -> Promise<KycState>? {
        return KycState.load(address: wallet.address.description)
    }
    
//    private var readState = WalletKycState.load()
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }

    func start() {
        setUpAndPrompt()
    }
    
    private func setUpAndPrompt() {
        
        showPrompt()
    }
    
    func showPrompt() {
        firstly {
            readState()!
        }.done { state in
            
            switch state.status {
            case "Init":
                self.createUnapprovedKycView()
                self.updateTabDelegate?.changeCollectToVerifyTab()
            case "Approved":
                self.createApprovedKycView()
                self.updateTabDelegate?.changeVerifyToCollectTab()
            case "Pending":
                self.createPenidngKycView()
                self.updateTabDelegate?.changeCollectToVerifyTab()
            case "Rejected":
                self.createRejectedKycView()
                self.updateTabDelegate?.changeCollectToVerifyTab()
            default:
                self.createUnapprovedKycView()
                self.updateTabDelegate?.changeCollectToVerifyTab()
            }
        }.catch { error in
            print("showprompt error: \(error)")
        }
    }
    
    private func createUnapprovedKycView() {
        let view = createKycViewImpl(viewModel: PromptUnapprovedKycViewModel(walletAddress: wallet.address))
        prominentPromptView = view
        let view1 = createKycViewImpl(viewModel: PromptUnapprovedKycViewModel(walletAddress: wallet.address))
                subtlePromptView = view1
        informDelegatesPromptHasChanged()
    }
    
    private func createApprovedKycView() {
        let view = createKycViewImpl(viewModel: PromptApprovedKycViewModel(walletAddress: wallet.address))
        prominentPromptView = view
        let view1 = createKycViewImpl(viewModel: PromptApprovedKycViewModel(walletAddress: wallet.address))
                subtlePromptView = view1
        informDelegatesPromptHasChanged()
    }
    
    private func createPenidngKycView() {
        let view = createKycViewImpl(viewModel: PromptPendingKycViewModel(walletAddress: wallet.address))
        prominentPromptView = view
        let view1 = createKycViewImpl(viewModel: PromptPendingKycViewModel(walletAddress: wallet.address))
                subtlePromptView = view1
        informDelegatesPromptHasChanged()
    }
    
    private func createRejectedKycView() {
        let view = createKycViewImpl(viewModel: PromptRejectedKycViewModel(walletAddress: wallet.address))
        prominentPromptView = view
        let view1 = createKycViewImpl(viewModel: PromptRejectedKycViewModel(walletAddress: wallet.address))
                subtlePromptView = view1
        informDelegatesPromptHasChanged()
    }
    
    private func createKycViewImpl(viewModel: PromptKycViewModel) -> UIView {
        let view = PromptKycView(viewModel: viewModel)
        view.delegate = self
        view.configure()
        return view
    }
    
    private func informDelegatesPromptHasChanged() {
        subtlePromptDelegate?.updatePrompt(inCoordinator: self)
        prominentPromptDelegate?.updatePrompt(inCoordinator: self)
    }
    
    private func removeBackupView() {
        prominentPromptView = nil
        subtlePromptView = nil
        informDelegatesPromptHasChanged()
    }
}

extension PromptKycCoordinator: PromptKycViewDelegate {

    func didChooseVerify(inView view: PromptKycView) {
        prominentPromptDelegate?.startVerification(URL(string: Constants.dappsBrowserURL)!)
    }
}
