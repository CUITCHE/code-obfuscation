//
//  Arguments.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/7.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

struct Arguments {
    /// [-id] info.plist的文件目录。默认为当前路径
    public var infoPlistFilepath = "."
    /// [-offset] 设置混淆名字的偏移量。默认为0，即每次都是随机值的偏移。
    public var obfuscationOffset = 0
    /// [-release|-debug] true: 只在release下才会替换混淆命名；false: 任何时候都会启用混淆命名。默认false。
    public var onlyDebug         = false
    /// [-db] 混淆字符映射的字典存放目录。默认是本程序执行的目录。
    public var dbFilepath        = "."
    /// [-root] 需要混淆的工程路径。默认为当前运行根目录。
    public var rootpath          = "."

    /// app 标识符，例如：club.we-code.obfuscation，默认club.we-code.obfuscation
    private(set) public var identifier         = "club.we-code.obfuscation"
    private(set) public var appVersion: String = "1.0.0"
    init() {
        if let arguments = Process().arguments {
            guard arguments.count > 1 else {
                return
            }
            for idx in 1..<arguments.count {
                if idx % 2 == 0 {
                    continue
                }
                let str = arguments[idx]
                switch str {
                case "-id":
                    if idx + 1 == arguments.count {
                        print("Argument error for \(str)")
                        exit(-9)
                    }
                    infoPlistFilepath = arguments[idx + 1]
                    if let infoBunlde = Bundle.init(path: infoPlistFilepath), let path = infoBunlde.path(forResource: "info", ofType: "plist"), let dict = NSDictionary.init(contentsOfFile: path) {
                        if let str = (dict[kCFBundleVersionKey as Any] as? String) {
                            appVersion = str
                        }
                        if let str = (dict[kCFBundleIdentifierKey as Any] as? String) {
                            identifier = str
                        }
                    }
                case "-offset":
                    if idx + 1 == arguments.count {
                        print("Argument error for \(str)")
                        exit(-9)
                    }
                    obfuscationOffset = Int.init(arguments[idx + 1]) ?? 0
                case "-release":
                    onlyDebug = true
                case "-root":
                    if idx + 1 == arguments.count {
                        print("Argument error for \(str)")
                        exit(-9)
                    }
                    rootpath = arguments[idx + 1]
                case "-debug":
                    onlyDebug = false
                case "-db":
                    if idx + 1 == arguments.count {
                        print("Argument error for \(str)")
                        exit(-9)
                    }
                    dbFilepath = arguments[idx + 1]
                default:
                    break
                }
            }
        }
    }
}

extension Arguments {
    static public let arguments = Arguments.init()
}
