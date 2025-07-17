//
//  MailComposeView.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 30/01/2025.
//


import SwiftUI
import MessageUI
import CocoaLumberjack

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var recipients: [String]
    var subject: String
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                DDLogDebug("Mail compose dismissed.")
            }
            self.parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = context.coordinator
        mailComposeVC.setToRecipients(recipients)
        mailComposeVC.setSubject(subject)
        return mailComposeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
}
