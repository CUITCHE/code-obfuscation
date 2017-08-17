//
//  flag.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/7/10.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate protocol Value {

    /// 返回值的string形式，要求返回的string能转换成值
    var string: String { get }

    /// 用string设置值
    ///
    /// - Parameter str: 值的string形式
    /// - Returns: optional类型，如果改string不能匹配到值，则返回一个字符串表示出错。
    func set(str: String) -> String?
}


public struct Flag {
    let name: String
    let usage: String
    fileprivate var value: Value
    fileprivate let defValue: String

    var isBoolFlag: Bool {
        return value is _Bool
    }

    static func unquoteUsage(flag: Flag) -> (name: String, usage: String) {
        let usage = flag.usage as NSString
        let first = usage.range(of: "`")
        let second = usage.range(of: "`", options: .backwards, range: NSRange.init(location: 0, length: usage.length), locale: nil)
        if first.location != second.location {
            let name = usage.substring(with: NSRange.init(location: first.location + 1, length: second.location - first.location - 1))
            let usageNew = usage.substring(to: first.location) + name + usage.substring(from: second.location + 1)
            return (name: name, usage: usageNew)
        }
        var name = "value"
        if flag.value is _Bool {
            name = ""
        } else if flag.value is _Integer {
            name = "int"
        } else if flag.value is _Float {
            name = "float"
        } else if flag.value is _String {
            name = "string"
        }

        return (name: name, usage: usage as String)
    }
}

public typealias __bool = Bool

fileprivate class _Bool: Value {
    var val: UnsafeMutablePointer<__bool>

    init(booleanLiteral value: Bool) {
        self.val = UnsafeMutablePointer<__bool>.allocate(capacity: MemoryLayout<__bool>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<__bool>.size)
    }

    fileprivate func set(str: String) -> String? {
        if let b = Bool(str) {
            val.pointee = b
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return val.pointee ? "true" : "false"
    }
}

fileprivate class _Integer: Value {
    var val: UnsafeMutablePointer<sint64>
    init(value: sint64) {
        self.val = UnsafeMutablePointer<sint64>.allocate(capacity: MemoryLayout<sint64>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<sint64>.size)
    }

    func set(str: String) -> String? {
        if let val = sint64(str) {
            self.val.pointee = val
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return String(self.val.pointee)
    }
}

fileprivate class _Float: Value {
    var val: UnsafeMutablePointer<Double>

    init(value: Double) {
        self.val = UnsafeMutablePointer<Double>.allocate(capacity: MemoryLayout<Double>.size)
        self.val.initialize(to: value)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<Double>.size)
    }

    func set(str: String) -> String? {
        if let val = Double(str) {
            self.val.pointee = val
        } else {
            return "invalid syntax"
        }
        return nil
    }

    var string: String {
        return String(self.val.pointee)
    }
}

fileprivate class _String: Value {
    var val: UnsafeMutablePointer<NSString>

    init(value: String) {
        self.val = UnsafeMutablePointer<NSString>.allocate(capacity: MemoryLayout<NSString>.size)
        self.val.initialize(to: value as NSString)
    }

    deinit {
        val.deinitialize()
        val.deallocate(capacity: MemoryLayout<NSString>.size)
    }

    func set(str: String) -> String? {
        self.val.pointee = str as NSString
        return nil
    }

    var string: String {
        return self.val.pointee as String
    }
}

public struct FlagSet {
    let name: String
    fileprivate var parsed = false
    fileprivate var formal = [String: Flag]()
    fileprivate var actual = [String: Flag]()
    var args: [String]
    var output: UnsafeMutablePointer<FILE>? = nil
    init() {
        var argv = CommandLine.arguments
        let name = argv.removeFirst()
        self.name = (name as NSString).lastPathComponent
        self.args = argv
    }
}

fileprivate extension FlagSet {
    func out() -> UnsafeMutablePointer<FILE> {
        if self.output == nil {
            return stderr
        }
        return self.output!
    }

    mutating func bindVariable(value: Value, name: String, usage: String) {
        if formal.index(forKey: name) != nil {
            var msg: String
            if self.name.characters.count == 0 {
                msg = "flag redefined: \(name)"
            } else {
                msg = "\(self.name) flag redefined: \(name)"
            }
            putln(text: msg)
        }
        let flag = Flag.init(name: name, usage: usage, value: value, defValue: value.string)
        formal[name] = flag
    }

    mutating func Bool(value: Bool, name: String, usage: String) -> UnsafePointer<__bool> {
        let bool = _Bool.init(booleanLiteral: value)
        self.bindVariable(value: bool, name: name, usage: usage)
        return UnsafePointer<__bool>(bool.val)
    }

    mutating func Integer(value: sint64, name: String, usage: String) -> UnsafePointer<sint64> {
        let integer = _Integer.init(value: value)
        self.bindVariable(value: integer, name: name, usage: usage)
        return UnsafePointer<sint64>(integer.val)
    }

    mutating func Float(value: Double, name: String, usage: String) -> UnsafePointer<Double> {
        let float = _Float.init(value: value)
        self.bindVariable(value: float, name: name, usage: usage)
        return UnsafePointer<Double>(float.val)
    }

    mutating func string(value: String, name: String, usage: String) -> UnsafePointer<NSString> {
        let string = _String.init(value: value)
        self.bindVariable(value: string, name: name, usage: usage)
        return UnsafePointer<NSString>(string.val)
    }


    mutating func parse() {
        self.parsed = true
        while true {
            let (seen, error) = self.parseOne()
            if seen {
                continue
            }
            if error == nil {
                break
            }
            putln(text: error!)
            exit(2)
        }
    }

    mutating func parseOne() -> (Bool, String?) {
        if args.isEmpty {
            return (false, nil)
        }

        let s = args[0]
        if s.characters.count == 0 || s[s.startIndex] != "-" || s.characters.count == 1 {
            return (false, "Unknown identifier: \(s)")
        }

        var numMinuses = 1
        if s[s.index(after: s.startIndex)] == "-" {
            if s.characters.count == 2 {
                args.removeFirst()
                return (false, nil)
            }
            numMinuses += 1
        }

        var name = s.substring(from: s.index(s.startIndex, offsetBy: numMinuses))
        if name.characters.count == 0 || name[name.startIndex] == "-" || name[name.startIndex] == "=" {
            return (false, "bad flag syntax: \(s)")
        }

        args.removeFirst()
        var hasValue = false
        var value = ""
        for (i, ch) in name.characters.dropFirst().enumerated() {
            if ch == "=" {
                hasValue = true
                value = (name as NSString).substring(from: i + 1 + 1)
                name = (name as NSString).substring(to: i + 1)
                break
            }
        }
        let flag = formal[name]
        if let flag = flag {
            if flag.isBoolFlag { // special case: doesn't need an arg
                if hasValue {
                    if let err = flag.value.set(str: value) {
                        return (false, "invalid boolean value \(value) for -\(name): \(err)")
                    }
                } else {
                    if let err = flag.value.set(str: "true") {
                        return (false, "invalid boolean value for -\(name): \(err)")
                    }
                }
            } else {
                // It must have a value, which might be the next argument.
                if hasValue == false && args.count > 0 {
                    hasValue = true
                    value = args.removeFirst()
                }
                if hasValue == false {
                    return (false, "flag needs an argument: -\(name)")
                }
                if let err = flag.value.set(str: value) {
                    return (false, "invalid value \(value) for flag -\(name): \(err)");
                }
            }
        } else {
            if name == "help" || name == "h" { // special case for nice help message.
                self.usage()
                exit(0)
            }
            return (false, "flag provided but not defined: -\(name)")
        }
        actual[name] = flag
        return (true, nil)
    }
}

public extension FlagSet {
    fileprivate func usage() {
        defaultUsage()
    }

    public func defaultUsage() {
        if name.characters.count == 0 {
            putln(text: "Usage:")
        } else {
            putln(text: "Usage of \(name):")
        }
        printDefault()
    }

    public func printDefault() {
        self.visitAll { (flag) in
            let name = "  -\(flag.name)" // Two spaces before -; see next two comments.
            var s = ""
            let info = Flag.unquoteUsage(flag: flag)
            if info.name.characters.count > 0 {
                s += " " + info.name
            }
            // Boolean flags of one ASCII letter are so common we
            // treat them specially, putting their usage on the same line.
            if s.characters.count + name.characters.count <= 4 {
                s += "\t"
            } else {
                // Four spaces before the tab triggers good alignment
                // for both 4- and 8-space tab stops.
                s += "\n    \t"
            }
            s += info.usage
            if isZeroValue(flag: flag, value: flag.defValue) == false {
                if flag.value is _String {
                    s += " (default \"\(flag.defValue)\")"
                } else {
                    s += " (default \(flag.defValue))"
                }
            }
            s += "\n"
            print(colorText: name, otherText: s)
        }
    }

    public func visitAll(fn: (_ flag: Flag) -> Void) {
        let values = formal.values.sorted { $0.name < $1.name }
        for flag in values {
            fn(flag)
        }
    }

    fileprivate func putln(text: String) {
        fputs("\(text)\n", stderr)
    }

    fileprivate func print(colorText: String, otherText: String) {
        fputs("\u{001b}[0;1m\(colorText)\u{001b}[0m\(otherText)\n", stderr)
    }

    fileprivate func isZeroValue(flag: Flag, value: String) -> Bool {
        // Build a zero value of the flag's Value type, and see if the
        // result of calling its String method equals the value passed in.
        // This works unless the Value type is itself an interface type.
        switch value {
        case "false":
            return true
        case "":
            return true
        case "0":
            return true
        default:
            return false
        }
    }
}


fileprivate var FlagCommandLine = FlagSet.init()


@objc
public class flag: NSObject {

    static func Bool(name: String, defValue: Bool, usage: String) -> UnsafePointer<__bool> {
        return FlagCommandLine.Bool(value: defValue, name: name, usage: usage)
    }

    static func Integer(name: String, defValue: sint64, usage: String) -> UnsafePointer<sint64> {
        return FlagCommandLine.Integer(value: defValue, name: name, usage: usage)
    }

    static func Float(name: String, defValue: Double, usage: String) -> UnsafePointer<Double> {
        return FlagCommandLine.Float(value: defValue, name: name, usage: usage)
    }

    static func String(name: String, defValue: String, usage: String) -> UnsafePointer<NSString> {
        let str = FlagCommandLine.string(value: defValue, name: name, usage: usage)
        return str
    }

    static func parse() {
        FlagCommandLine.parse()
    }

    static func parsed() -> Bool {
        return FlagCommandLine.parsed
    }

    static public var executedPath: String {
        get {
            return CommandLine.arguments.first ?? ""
        }
    }
}
