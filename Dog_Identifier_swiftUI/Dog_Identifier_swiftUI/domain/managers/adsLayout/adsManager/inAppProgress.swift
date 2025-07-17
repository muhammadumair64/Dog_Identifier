//
//  inAppProgress.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 21/02/2025.
//
import Foundation
import StoreKit
import CocoaLumberjack

protocol inAppProgress {
    func progress(error: String)
}

final class InAPPManager:NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver{
    static let shared = InAPPManager()
    
    var products = [SKProduct]()
    private var completion: ((Double,Bool) -> Void)?
    
    var inAppProgressLoading: inAppProgress?
    enum Product: String, CaseIterable{
        case premium_dog
        
        var count: Double{
            switch self {
            case .premium_dog :
                return 4.99
            }
        }
    }
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self) // ✅ Observer add kar diya
    }
    
    deinit {
        SKPaymentQueue.default().remove(self) // ✅ Observer remove kar diya
    }
    
    public func fetchProducts() {
        let productIDs = Set(Product.allCases.compactMap({ $0.rawValue }))
        
        if productIDs.isEmpty {
            print("⚠️ Error: Product Identifiers are empty!")
            return
        }
        
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
        
        print("✅ Request sent for products: \(productIDs)")
    }
    
    // MARK: - Restore Purchases
    func restoreSubscriptions() {
        guard SKPaymentQueue.canMakePayments() else {
            print("⚠️ In-App Purchases are disabled")
            return
        }
        
        SKPaymentQueue.default().restoreCompletedTransactions()
        UserDefaultManager.shared.set(false, forKey: .isPremiumUser)
        
        DispatchQueue.main.async {
            self.inAppProgressLoading?.progress(error: "restored")
        }
    }
    
    // MARK: - STOREKIT DELEGATE METHODS
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        print("PRODUCT RETURNS: - \(response.products.count)")
        
        self.products = response.products
        if let product = response.products.first{
            let priceFormatter = NumberFormatter()
            priceFormatter.locale = product.priceLocale
            
            if(product.price == 0){
                UserDefaultManager.shared.set("4.99$", forKey: UserDefaultManager.Key.PRICE)
            }else{
                UserDefaultManager.shared.set(product.price, forKey: UserDefaultManager.Key.PRICE)
            }
            
            fetchLocalizedPrice(for: product)
        } else {
            UserDefaultManager.shared.set("4.99$", forKey: UserDefaultManager.Key.PRICE)
        }
    }
    
    func fetchLocalizedPrice(for product: SKProduct) {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        
        if let localizedPrice = priceFormatter.string(from: product.price) {
            print("Product ID: \(product.productIdentifier), Localized Price: \(localizedPrice)")
            UserDefaultManager.shared.set(localizedPrice, forKey: .PRICE)
            // Here you can handle the localized price for each product
            // You might want to store it or use it in some other way
        }
    }
    
//    public func Purchase(product: Product, completion: @escaping ((Double , Bool) -> Void )){
//        guard SKPaymentQueue.canMakePayments() else {
//            self.completion = completion(0, false)
//            return
//        }
//        guard let storekitProduct = products.first(where: {$0.productIdentifier == product.rawValue}) else { return }
//        
//        self.completion = completion
//        
//        let paymentRequest = SKPayment(product: storekitProduct)
//        SKPaymentQueue.default().add(self)
//        SKPaymentQueue.default().add(paymentRequest)
//    }
    
    public func Purchase(product: Product, completion: @escaping ((Double, Bool) -> Void)) {
        guard SKPaymentQueue.canMakePayments() else {
            DDLogError("❌ User not allowed to make payments")
            completion(0, false) // ✅ just call it
            inAppProgressLoading?.progress(error: "disabled")
            return
        }

        guard let storekitProduct = products.first(where: { $0.productIdentifier == product.rawValue }) else {
            DDLogError("❌ Product not found in fetched list: \(product.rawValue)")
            completion(0, false)
            inAppProgressLoading?.progress(error: "not_found")
            return
        }

        self.completion = completion

        let paymentRequest = SKPayment(product: storekitProduct)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(paymentRequest)
    }

    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            switch transaction.transactionState {
            case .purchasing:
                print("⏳ Purchasing...")
                
            case .purchased:
                print("✅ Purchased")
                
                // ✅ Check if it's a new purchase (not a restore)
                if transaction.original == nil {
                    print("🎉 New Purchase Detected")
                    if let product = Product(rawValue: transaction.payment.productIdentifier) {
                        completion?(product.count,true)
                    }
                    inAppProgressLoading?.progress(error: "purchased")
                }
                
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .restored:
                print("🔄 Restored Purchase")
                inAppProgressLoading?.progress(error: "restored")
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                print("❌ Purchase Failed")
                completion?(0,false)
                inAppProgressLoading?.progress(error: "failed")
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .deferred:
                print("⏳ Payment Deferred")
                
            @unknown default:
                break
            }
        }
    }
    
}
