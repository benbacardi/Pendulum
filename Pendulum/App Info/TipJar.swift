//
//  TipJar.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/02/2023.
//

import Foundation
import StoreKit

enum TipJar: String, CaseIterable {
    case extraFine = "uk.co.bencardy.Pendulum.ExtraFineTip"
    case fine = "uk.co.bencardy.Pendulum.FineTip"
    case medium = "uk.co.bencardy.Pendulum.MediumTip"
    case broad = "uk.co.bencardy.Pendulum.BroadTip"
    case stub = "uk.co.bencardy.Pendulum.StubTip"
    
    var name: String {
        switch self {
        case .extraFine:
            return "Extra Fine"
        case .fine:
            return "Fine"
        case .medium:
            return "Medium"
        case .broad:
            return "Broad"
        case .stub:
            return "Stub"
        }
    }
    
    var lowerCaseName: String {
        name.lowercased()
    }
    
}

extension TipJar {
    
    func purchase(_ product: Product) async -> Bool {
        storeLogger.debug("Attempting to purchase \(self.rawValue)")
        do {
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verificationResult):
                storeLogger.debug("Purchase result: success")
                switch verificationResult {
                case .verified(let transaction):
                    storeLogger.debug("Purchase success result: verified")
                    await transaction.finish()
                    return true
                default:
                    storeLogger.debug("Purchase success result: unverified")
                    return false
                }
            default:
                return false
            }
        } catch {
            storeLogger.error("Could not purchase \(self.rawValue): \(error.localizedDescription)")
            return false
        }
    }
    
    static func fetchProducts() async -> [Self: Product] {
        do {
            let products = try await Product.products(for: Self.allCases.map { $0.rawValue })
            var results: [Self: Product] = [:]
            for product in products {
                if let type = TipJar(rawValue: product.id) {
                    results[type] = product
                }
            }
            return results
        } catch {
            storeLogger.error("Could not fetch products: \(error.localizedDescription)")
            return [:]
        }
    }
    
}
