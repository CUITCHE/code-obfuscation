//
//  Arguments.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/7/12.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate struct __Arguments {
    let id = flag.String(name: "id", defValue: ".", usage: "The directory of info.plist. Default is current executed path.")
    let offset = flag.Integer(name: "offset", defValue: 0, usage: "The offset of obfuscation. Default is 0.")
    let db = flag.String(name: "db", defValue: ".", usage: "The directory of obfuscation database. Default is current executed path.")
    let root = flag.String(name: "root", defValue: ".", usage: "The directory of project file or what you want to start. Default is current executed path.")
    let `super` = flag.Bool(name: "super", defValue: false, usage: "Check the user-class' names which have been entranced obfuscation whethere their super classes exist or not. If exists, will info a warning. For strict option, will check all of classes of iOS Kits.")
    let strict = flag.Bool(name: "strict", defValue: false, usage: "See -super.")
    let st = flag.Bool(name: "st", defValue: true, usage: "Strengthen the obfuscation. Default is true.")
    let version = flag.Bool(name: "version", defValue: false, usage: "Get the program supported iOS SDK version.")
}

public struct Arguments {
    fileprivate let __arguments = __Arguments.init()
    public var infoPlistFilepath: NSString { return __arguments.id.pointee }
    public var obfuscationOffset: sint64 { return __arguments.offset.pointee }
    public var dbFilepath: NSString { return __arguments.db.pointee }
    public var rootpath : NSString { return __arguments.root.pointee }

    public var supercheck: Bool { return __arguments.`super`.pointee }
    public var strict: Bool { return __arguments.strict.pointee }
    public var st: Bool { return __arguments.st.pointee }

    public var executedPath: String { return flag.executedPath }

    public var identifier: String {
        if let infoBundle = Bundle.init(path: infoPlistFilepath as String), let path = infoBundle.path(forResource: "info", ofType: "plist"), let dict = NSDictionary.init(contentsOfFile: path) {
            if let id = dict[kCFBundleIdentifierKey as Any] as? String {
                return id
            }
        }
        return "club.we-code.obfuscation"
    }
    public var appVersion: String {
        if let infoBundle = Bundle.init(path: infoPlistFilepath as String), let path = infoBundle.path(forResource: "info", ofType: "plist"), let dict = NSDictionary.init(contentsOfFile: path) {
            if let ver = dict[kCFBundleVersionKey as Any] as? String {
                return ver
            }
        }
        return "1.0.0"
    }

    public init() {
        if flag.parsed() == false {
            flag.parse()
        }
        if __arguments.version.pointee {
            Arguments.printVersion()
        }
    }

    public static let arguments = Arguments.init()
}

fileprivate extension Arguments {
    static func printVersion() {
        fputs(COCacheImage.version(), stderr)
        fputs("\n", stderr)
        exit(0)
    }
}
