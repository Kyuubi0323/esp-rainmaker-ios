// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: constants.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
private struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
    struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
    typealias Version = _2
}

/// Allowed values for the status
/// of a protocomm instance
enum Status: SwiftProtobuf.Enum {
    typealias RawValue = Int
    case success // = 0
    case invalidSecScheme // = 1
    case invalidProto // = 2
    case tooManySessions // = 3
    case invalidArgument // = 4
    case internalError // = 5
    case cryptoError // = 6
    case invalidSession // = 7
    case UNRECOGNIZED(Int)

    init() {
        self = .success
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 1: self = .invalidSecScheme
        case 2: self = .invalidProto
        case 3: self = .tooManySessions
        case 4: self = .invalidArgument
        case 5: self = .internalError
        case 6: self = .cryptoError
        case 7: self = .invalidSession
        default: self = .UNRECOGNIZED(rawValue)
        }
    }

    var rawValue: Int {
        switch self {
        case .success: return 0
        case .invalidSecScheme: return 1
        case .invalidProto: return 2
        case .tooManySessions: return 3
        case .invalidArgument: return 4
        case .internalError: return 5
        case .cryptoError: return 6
        case .invalidSession: return 7
        case let .UNRECOGNIZED(i): return i
        }
    }
}

#if swift(>=4.2)

    extension Status: CaseIterable {
        // The compiler won't synthesize support with the UNRECOGNIZED case.
        static var allCases: [Status] = [
            .success,
            .invalidSecScheme,
            .invalidProto,
            .tooManySessions,
            .invalidArgument,
            .internalError,
            .cryptoError,
            .invalidSession,
        ]
    }

#endif // swift(>=4.2)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension Status: SwiftProtobuf._ProtoNameProviding {
    static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
        0: .same(proto: "Success"),
        1: .same(proto: "InvalidSecScheme"),
        2: .same(proto: "InvalidProto"),
        3: .same(proto: "TooManySessions"),
        4: .same(proto: "InvalidArgument"),
        5: .same(proto: "InternalError"),
        6: .same(proto: "CryptoError"),
        7: .same(proto: "InvalidSession"),
    ]
}