//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation
import AWSPluginsCore
import Amplify

extension SRPSignInState: Codable {

    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignUpState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignOutState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInChallengeState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension RefreshSessionState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension DeleteUserState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension CustomSignInState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notStarted
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension CredentialStoreState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notConfigured
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension AuthState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notConfigured
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension AuthorizationState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notConfigured
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension AuthenticationState: Codable {
    public init(from decoder: Decoder) throws {
        self = .notConfigured
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension FetchAuthSessionState: Codable {

    enum CodingKeys: CodingKey {
        case notStarted
        case fetchingIdentityID
        case fetchingAWSCredentials
        case fetched
    }

    public init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let notStarted = try values.decodeIfPresent(Dictionary<String, String>.self, forKey: .notStarted) {
            self = .notStarted
        } else if let fetchingIdentityID = try values.decodeIfPresent(Dictionary<String, String>.self, forKey: .fetchingIdentityID) {
            self = .fetchingIdentityID(UnAuthLoginsMapProvider())
        } else if let fetchingAWSCredentials = try values.decodeIfPresent(Dictionary<String, String>.self, forKey: .fetchingAWSCredentials) {
            self = .fetchingAWSCredentials("someIdentityId", UnAuthLoginsMapProvider())
        } else if let fetched = try values.decodeIfPresent(Dictionary<String, String>.self, forKey: .fetched) {
            self = .fetched("someCredentials", AuthAWSCognitoCredentials(accessKey: "", secretKey: "", sessionKey: "", expiration: Date()))
        } else {
            fatalError()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    }
}

extension SignUpOutputResponse: Codable {
    enum CodingKeys: CodingKey {
        case codeDeliveryDetails
        case userConfirmed
        case userSub
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        self.userConfirmed = try containerValues.decode(Swift.Bool.self, forKey: .userConfirmed)
        self.codeDeliveryDetails = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType.self, forKey: .codeDeliveryDetails)
        self.userSub = try containerValues.decodeIfPresent(String.self, forKey: .userSub)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("This implementation is not needed")
    }
}

extension AuthorizationError: Codable {
    public init(from decoder: Decoder) throws {
        self = .sessionExpired
    }

    public func encode(to encoder: Encoder) throws {

    }
}

extension SignInError: Codable {

    enum CodingKeys: CodingKey {
        case configuration
        case inputValidation
        case invalidServiceResponse
        case calculation
        case hostedUI
        case service
        case unknown
    }

    public init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let configuration = try values.decodeIfPresent(String.self, forKey: .configuration) {
            self = .configuration(message: configuration)
        } else if let inputValidation = try values.decodeIfPresent(String.self, forKey: .inputValidation) {
            self = .inputValidation(field: inputValidation)
        } else if let invalidServiceResponse = try values.decodeIfPresent(String.self, forKey: .invalidServiceResponse) {
            self = .invalidServiceResponse(message: invalidServiceResponse)
        } else if let unknown = try values.decodeIfPresent(String.self, forKey: .unknown) {
            self = .unknown(message: unknown)
        } else if let calculation = try values.decodeIfPresent(SRPError.self, forKey: .calculation) {
            self = .calculation(calculation)
        } else {
            fatalError("Decoding the key not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {

        case .configuration(message: let message):
            try container.encode(message, forKey: .configuration)
        case .inputValidation(field: let message):
            try container.encode(message, forKey: .inputValidation)
        case .invalidServiceResponse(message: let message):
            try container.encode(message, forKey: .invalidServiceResponse)
        case .calculation(let error):
            try container.encode(error, forKey: .calculation)
        case .hostedUI(let error):
            fatalError("service error decoding not supported")
        case .service(let error):
            fatalError("service error decoding not supported")
        case .unknown(message: let message):
            try container.encode(message, forKey: .unknown)
        }
    }
}

extension SignUpError: Codable {

    enum CodingKeys: CodingKey {
        case invalidState
        case invalidUsername
        case invalidPassword
        case invalidConfirmationCode
        case service
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let invalidState = try values.decodeIfPresent(String.self, forKey: .invalidState) {
            self = .invalidState(message: invalidState)
        } else if let invalidUsername = try values.decodeIfPresent(String.self, forKey: .invalidUsername) {
            self = .invalidState(message: invalidUsername)
        } else if let invalidPassword = try values.decodeIfPresent(String.self, forKey: .invalidPassword) {
            self = .invalidState(message: invalidPassword)
        } else if let invalidConfirmationCode = try values.decodeIfPresent(String.self, forKey: .invalidConfirmationCode) {
            self = .invalidState(message: invalidConfirmationCode)
        } else {
            fatalError("Decoding the key not supported")
        }
        //      TODO: Check how we can decode swift error
        //        else if let invalidStateMessage = values.decodeIfPresent(String.self, forKey: .service) {
        //            self = .invalidState(message: invalidStateMessage)
        //        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {

        case .invalidState(message: let message):
            try container.encode(message, forKey: .invalidState)
        case .invalidUsername(message: let message):
            try container.encode(message, forKey: .invalidUsername)
        case .invalidPassword(message: let message):
            try container.encode(message, forKey: .invalidPassword)
        case .invalidConfirmationCode(message: let message):
            try container.encode(message, forKey: .invalidConfirmationCode)
        case .service(error: let error):
            fatalError("service error decoding not supported")
        }
    }
}

extension AuthError: Codable {
    public init(from decoder: Decoder) throws {
        self = .unknown("", nil)
    }

    public func encode(to encoder: Encoder) throws {

    }

}

extension FetchSessionError: Codable {
    public init(from decoder: Decoder) throws {
        self = .notAuthorized
    }

    public func encode(to encoder: Encoder) throws {

    }
}


extension KeychainStoreError: Codable {
    public init(from decoder: Decoder) throws {
        self = .unknown("", nil)
    }

    public func encode(to encoder: Encoder) throws {

    }
}
