//
//  TipJarView.swift
//  Pendulum
//
//  Created by Ben Cardy on 03/02/2023.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    
    @State private var tipJarPrices: [TipJar: Product] = [:]
    @State private var productsFetched: Bool = false
    @State private var pendingPurchase: TipJar? = nil
    @State private var showingSuccessAlert: Bool = false
    
    func isDisabled(for tip: TipJar) -> Bool {
        tipJarPrices[tip] == nil || (pendingPurchase != nil && pendingPurchase != tip)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                
                VStack(spacing: 10) {
                    Text("Pendulum is built with love by two friends, Alex and Ben, in their spare time. It is, and always will be, free to use. If you like using the app, feel free to leave a tip!")
                        .fullWidth()
                    Text("Thank you for using Pendulum; your support is gratefully received.")
                        .fullWidth()
                }
                .padding(.bottom)
                
                ForEach(TipJar.allCases, id: \.self) { tip in
                    Button(action: {
                        guard pendingPurchase == nil else { return }
                        storeLogger.debug("\(tip.rawValue) tapped")
                        if let product = tipJarPrices[tip] {
                            withAnimation {
                                pendingPurchase = tip
                            }
                            Task {
                                let successful = await tip.purchase(product)
                                storeLogger.debug("Successful? \(successful)")
                                DispatchQueue.main.async {
                                    withAnimation {
                                        showingSuccessAlert = successful
                                        pendingPurchase = nil
                                    }
                                }
                            }
                        }
                    }) {
                        GroupBox {
                            HStack {
                                Text("\(tip.name) Tip")
                                    .fullWidth()
                                if let product = tipJarPrices[tip] {
                                    if pendingPurchase == tip {
                                        ProgressView()
                                    } else {
                                        Text(product.displayPrice)
                                            .foregroundColor(.accentColor)
                                    }
                                } else {
                                    if productsFetched {
                                        Image(systemName: "exclamationmark.triangle")
                                    } else {
                                        ProgressView()
                                    }
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .disabled(isDisabled(for: tip))
                    .opacity(productsFetched ? (isDisabled(for: tip) ? 0.5 : 1) : 1)
                }
                
            }
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text("Purchase Successful"), message: Text("Thank you for supporting Pendulum!"), dismissButton: .default(Text("🧡")))
        }
        .padding()
        .task {
            let products = await TipJar.fetchProducts()
            DispatchQueue.main.async {
                withAnimation {
                    tipJarPrices = products
                    productsFetched = true
                }
            }
        }
        .navigationTitle("Support Pendulum")
    }
}

struct TipJarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TipJarView()
        }
    }
}
