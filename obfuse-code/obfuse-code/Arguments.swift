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
    let `super` = flag.Bool(name: "super", defValue: false, usage: "Check the user-class' names which have been entranced obfuscation whether their super classes exist or not. If exists, will info a warning. For strict option, will check all of classes of iOS Kits.")
    let strict = flag.Bool(name: "strict", defValue: false, usage: "See -super.")
    let st = flag.Bool(name: "st", defValue: true, usage: "Strengthen the obfuscation. Default is true.")
    let version = flag.Bool(name: "version", defValue: false, usage: "Get the program supported iOS SDK version.")
    let query = flag.String(name: "q", defValue: "", usage: "Query the method whether exist or not.")
    let showClass = flag.Bool(name: "class", defValue: false, usage: "Show the class name which method belogs to if you are in query command.")
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
        return "com.placeholder.co"
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
        if __arguments.query.pointee != "" {
            Arguments.query(with: __arguments.query.pointee as String)
        }
    }

    public static let arguments = Arguments.init()
}

fileprivate extension Arguments {
    static func printVersion() {
        printc.println(text: CacheImage.versionString)
        exit(0)
    }

    static func query(with statement: String) {
        let cache = CacheImage.init()
        var similarClass = [String]()
        var similarMethods = Set<String>.init()

        var size = winsize.init()
        var columns = 0
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) >= 0 {
            columns = Int(size.ws_col)
            if columns > 80 {
                columns = 80
            }
        }

        printc.console.IORedirector = stdout
        printc.console.isHideCursor = true
        printc.println(text: "🍺  searching...", marks: .yellow)
        let symbols = ["😀","😃","😄","😁","😆","😂","☺️","😊","🙂","😉","😌","😍","😘","😋","⚽️","🏀","🏈","⚾️","🎾","🏐","🏉","🎱","🏓","✔️","☯","🀫","🀰","〒"]
        let symbol = symbols[Int(arc4random()) % symbols.count]
        var mutex = pthread_mutex_t.init()
        pthread_mutex_init(&mutex, nil)
        cache.enumerateCache { (classname, methods, progress) -> Bool in
            if classname.contains(statement) {
                similarClass.append(classname.replacingOccurrences(of: statement, with: printc.write(statement, .bold, .red).takeAssembleBuffer()))
            }
            for m in methods {
                if m.method.contains(statement) {
                    similarMethods.insert(m.method.replacingOccurrences(of: statement, with: printc.write(statement, .bold, .red).takeAssembleBuffer()))
                }
            }
            if columns > 10 {
                let progressString = "\(progress)%"
                let rest = columns - progressString.characters.count
                let rate = Double(progress) / 100.0
                let doneInt = Int(Double(rest) * rate)
                pthread_mutex_lock(&mutex)
                printc.print(text: "\r")
                // print done
                printc.print(text: "\((0..<doneInt / 2).map({ _ in return "\(symbol) " }).joined())")
                // print will-do and rate
                printc.print(text: "\((0..<(rest - doneInt + ((doneInt & 1) == 1 ? 1: 0))).map({ _ in return " " }).joined())\(progressString)")
                pthread_mutex_unlock(&mutex)
            }
            if progress == 100 {
                printc.console.isHideCursor = false
                printc.println(text: "")
                if similarClass.count > 0 {
                    similarClass.sort(by: <)
                    printc.println(text: "Found similar class: ", marks: .bold)
                    printc.println(text: "\(similarClass.joined(separator: "\n"))\n")
                }
                if similarMethods.count > 0 {
                    printc.println(text: "Found similar method: ", marks: .bold)
                    var methods = similarMethods.sorted(by: <)
                    if let idx = methods.index(where: { return $0 == statement }) {
                        methods.remove(at: idx)
                        printc.println(text: statement, marks: .underline)
                    }
                    printc.println(text: "\(methods.joined(separator: "\n"))\n")
                }
                pthread_mutex_destroy(&mutex)
                exit(0)
            }
            return false
        }
        RunLoop.main.run()
    }
}
