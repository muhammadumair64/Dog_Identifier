//
//  Alerts.swift
//  IosFirstApp
//
//  Created by Mac Mini on 13/09/2024.
//

import SwiftUI

struct AlertMessage :Identifiable {
    let id = UUID()
    let title:Text
    let message:Text
    let dismissButton: Alert.Button
}

struct AlertContext {
    static let invalidData = AlertMessage(
        title: Text(
            "Server Error"
        ),
        message: Text(
            "The data received from the server was invalid. Please contact support."
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    static let invalidResponse = AlertMessage(
        title: Text(
            "Server Error"
        ),
        message: Text(
            "Invalid response from server. Please contact support"
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    static let invalidURL = AlertMessage(
        title: Text(
            "Server Error"
        ),
        message: Text(
            "There was an issue connecting to the server. Please contact support."
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    static let unableToComplete = AlertMessage(
        title: Text(
            "Server Error"
        ),
        message: Text(
            "Unable to complete your request at this time. Please check your internet"
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    
    static let invalidForm = AlertMessage(
        title: Text(
            "Invalid Form"
        ),
        message: Text(
            "Invalid Fields. Please Fill Form Correctly."
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    static let invalidEmail = AlertMessage(
        title: Text(
            "Invalid Email"
        ),
        message: Text(
            "Your email is not valid. Please enter email carefully"
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    
    static let unableToScan = AlertMessage(
        title: Text(
            "ERROR"
        ),
        message: Text(
            "Unable to scan image. Please try again"
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    
    static let imageUnavailable = AlertMessage(
        title: Text(
            "ERROR"
        ),
        message: Text(
            "Image not available. Please try again"
        ),
        dismissButton:.default(
            Text(
                "OK"
            )
        )
    )
    
    
    
}
