//
//  KycState.swift
//  UBIWallet
//
//  Created by apollo on 6/7/22.
//

import Foundation
import Alamofire
import PromiseKit

struct KycState: Codable {
    let code: String
    let status: String
    let message: String
    
    static func load(address: String) -> Promise<KycState>? {
        return Alamofire.request("https://jaxcorp.com:8443/ubi_status/\(address)", method: .get).responseDecodable(KycState.self)
    }
}

struct WalletKycState: Codable {
    
    enum Prompt {
        case unapproved
        case approved
        case pending
        case rejected
    }
    
    var prompt = [AlphaWallet.Address: Prompt]()
    
}

extension WalletKycState.Prompt: Codable {
    enum Key: CodingKey {
        case rawValue
        case associatedValue
    }

    enum CodingError: Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        print("show prompt rawvalue \(rawValue)")
        switch rawValue {
        case 0:
            self = .unapproved
        case 1:
            self = .approved
        case 2:
            self = .pending
        case 3:
            self = .rejected
        default:
            throw CodingError.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        print("show prompt self \(self)")
        switch self {
        case .unapproved:
            try container.encode(0, forKey: .rawValue)
        case .approved:
            try container.encode(1, forKey: .rawValue)
        case .pending:
            try container.encode(2, forKey: .rawValue)
        case .rejected:
            try container.encode(3, forKey: .rawValue)
        }
    }
}
