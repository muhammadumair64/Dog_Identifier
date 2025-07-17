import SwiftUI

class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var isShowing: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var primaryButtonTitle: String = ""
    @Published var secondaryButtonTitle: String? = nil
    @Published var primaryAction: (() -> Void)? = nil
    @Published var secondaryAction: (() -> Void)? = nil
    @Published var isSecondaryButtonVisible: Bool = false // New property to control visibility
    
    private init() {}
    
    func showAlert(
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryButtonTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        showSecondaryButton: Bool = false // New parameter to toggle visibility
    ) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryAction = primaryAction
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryAction = secondaryAction
        self.isSecondaryButtonVisible = showSecondaryButton // Set visibility
        self.isShowing = true
    }
    
    func dismiss() {
        isShowing = false
    }
}

import SwiftUI

struct CustomAlertView: View {
    @ObservedObject var alertManager = AlertManager.shared
    
    var body: some View {
        if alertManager.isShowing {
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    Text(alertManager.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(alertManager.message)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        if alertManager.isSecondaryButtonVisible, let secondaryTitle = alertManager.secondaryButtonTitle {
                            Button(action: {
                                alertManager.secondaryAction?()
                                alertManager.dismiss()
                            }) {
                                Text(secondaryTitle)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                        
                        Button(action: {
                            alertManager.primaryAction?()
                            alertManager.dismiss()
                        }) {
                            Text(alertManager.primaryButtonTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ColorHelper.primary.color)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
            }
            .animation(.easeInOut, value: alertManager.isShowing)
            .transition(.opacity)
        }
    }
}

// MARK: - Usage

/*AlertManager.shared.showAlert(
                   title: "Confirmation",
                   message: "Do you want to continue?",
                   primaryButtonTitle: "Yes",
                   primaryAction: {
                       print("Yes tapped")
                   },
                   secondaryButtonTitle: "No",
                   secondaryAction: {
                       print("No tapped")
                   },
                   showSecondaryButton: true // Show the second button
               )*/
