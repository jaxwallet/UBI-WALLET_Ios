//
//  TransactionConfirmationCoordinatorBridgeToPromise.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 30.10.2020.
//

import UIKit
import PromiseKit
import Result

private class TransactionConfirmationCoordinatorBridgeToPromise {
    private let analyticsCoordinator: AnalyticsCoordinator
    private let navigationController: UINavigationController
    private let session: WalletSession
    private let coordinator: Coordinator & CanOpenURL
    private let (promise, seal) = Promise<ConfirmResult>.pending()
    private var retainCycle: TransactionConfirmationCoordinatorBridgeToPromise?
    private weak var confirmationCoordinator: TransactionConfirmationCoordinator?
    private var didSendTransactionClosure: ((SentTransaction) -> Void)?

    init(_ navigationController: UINavigationController, session: WalletSession, coordinator: Coordinator & CanOpenURL, analyticsCoordinator: AnalyticsCoordinator, didSendTransactionClosure: @escaping (SentTransaction) -> Void) {
        self.navigationController = navigationController
        self.session = session
        self.coordinator = coordinator
        self.analyticsCoordinator = analyticsCoordinator
        retainCycle = self
        self.didSendTransactionClosure = didSendTransactionClosure
        promise.ensure {
            //NOTE: Ensure we break the retain cycle, and remove coordinator from list
            self.retainCycle = nil

            if let coordinatorToRemove = coordinator.coordinators.first(where: { $0 === self.confirmationCoordinator }) {
                coordinator.removeCoordinator(coordinatorToRemove)
            }
        }.cauterize()
    }

    func promise(transaction: UnconfirmedTransaction, configuration: TransactionConfirmationConfiguration, source: Analytics.TransactionConfirmationSource) -> Promise<ConfirmResult> {
        let confirmationCoordinator = TransactionConfirmationCoordinator(presentingViewController: navigationController, session: session, transaction: transaction, configuration: configuration, analyticsCoordinator: analyticsCoordinator)

        confirmationCoordinator.delegate = self
        self.confirmationCoordinator = confirmationCoordinator
        coordinator.addCoordinator(confirmationCoordinator)
        confirmationCoordinator.start(fromSource: source)

        return promise
    }
}

extension TransactionConfirmationCoordinatorBridgeToPromise: TransactionConfirmationCoordinatorDelegate {
    func didPress(for type: PaymentFlow, server: RPCServer, inViewController viewController: UIViewController?, in coordinator: TransactionConfirmationCoordinator) {
        
    }
    
    func didSendTransaction(_ transaction: SentTransaction, inCoordinator coordinator: TransactionConfirmationCoordinator) {
        didSendTransactionClosure?(transaction)
        didSendTransactionClosure = .none
    }

    func didFinish(_ result: ConfirmResult, in coordinator: TransactionConfirmationCoordinator) {
        coordinator.close().done { _ in
            self.seal.fulfill(result)
        }.cauterize()
    }

    func coordinator(_ coordinator: TransactionConfirmationCoordinator, didFailTransaction error: AnyError) {
        coordinator.close().done { _ in
            //no op
        }.ensure {
            self.seal.reject(error)
        }.cauterize()
    }

    func didClose(in coordinator: TransactionConfirmationCoordinator) {
        seal.reject(DAppError.cancelled)
    }
}

extension TransactionConfirmationCoordinatorBridgeToPromise: CanOpenURL {
    func didPressViewContractWebPage(forContract contract: AlphaWallet.Address, server: RPCServer, in viewController: UIViewController) {
        coordinator.didPressViewContractWebPage(forContract: contract, server: server, in: viewController)
    }

    func didPressViewContractWebPage(_ url: URL, in viewController: UIViewController) {
        coordinator.didPressViewContractWebPage(url, in: viewController)
    }

    func didPressOpenWebPage(_ url: URL, in viewController: UIViewController) {
        coordinator.didPressOpenWebPage(url, in: viewController)
    }
}

extension UIViewController {

    func displayErrorPromise(message: String) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.popoverPresentationController?.sourceView = view
        let action = UIAlertAction(title: R.string.localizable.oK(), style: .default) { _ in
            seal.fulfill(())
        }

        alertController.addAction(action)

        present(alertController, animated: true)

        return promise
    }
}

extension TransactionConfirmationCoordinator {
    // NOTE: Hack usage of closure `didSendTransactionClosure`, its not good to do like that,
    // made to easily get called `didSendTransaction` method as promise can't be called twice
    static func promise(_ navigationController: UINavigationController, session: WalletSession, coordinator: Coordinator & CanOpenURL, transaction: UnconfirmedTransaction, configuration: TransactionConfirmationConfiguration, analyticsCoordinator: AnalyticsCoordinator, source: Analytics.TransactionConfirmationSource, didSendTransactionClosure: @escaping (SentTransaction) -> Void) -> Promise<ConfirmResult> {
        let bridge = TransactionConfirmationCoordinatorBridgeToPromise(navigationController, session: session, coordinator: coordinator, analyticsCoordinator: analyticsCoordinator, didSendTransactionClosure: didSendTransactionClosure)
        return bridge.promise(transaction: transaction, configuration: configuration, source: source)
    }
}
