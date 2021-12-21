//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Security

public enum AmplifyKeychainError {

    /// Caused by an unknown reason
    case unknown(ErrorDescription, Error? = nil)

    /// Caused by trying to convert String to Data or vice-versa
    case conversionError(ErrorDescription, Error? = nil)

    /// Unable to find the keychain item
    case itemNotFound

    /// Caused trying to perform a keychain operation, examples, missing entitlements, missing required attributes, etc
    case securityError(OSStatus)
}

extension AmplifyKeychainError: AmplifyError {

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "(Ignored)",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else if error.isOperationCancelledError {
            self = .unknown("Operation cancelled", error)
        } else {
            self = .unknown(errorDescription, error)
        }
    }

    /// Error Description
    public var errorDescription: ErrorDescription {
        switch self {
        case .conversionError(let errorDescription, _):
            return errorDescription
        case .securityError(let status):
            return "Keychain error occurred with status: \(status)"
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .itemNotFound:
            return "Unable to find the keychain item"
        }
    }

    /// Recovery Suggestion
    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown, .conversionError, .securityError, .itemNotFound:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    /// Underlying Error
    public var underlyingError: Error? {
        switch self {
        case .conversionError(_, let error):
            return error
        case .unknown(_, let error):
            return error
        default:
            return nil
        }
    }

}
