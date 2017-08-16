//
//  Clazz.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/8/15.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

///////////////////////////////////////////////////////////////////// COProperty
class COProperty: NSObject, FakeProtocol {
    let name: String
    let location: NSRange

    override var description: String { return name }
    override var debugDescription: String { return "(\(name), \(location))" }

    init(name: String, location: NSRange = NSRange()) {
        self.name     = name
        self.location = location
    }

    // protocol
    var fakename: String? = nil
    var oriname: String { return name }
}

///////////////////////////////////////////////////////////////////// COSelectorPart
class SelectorPart: NSObject, FakeProtocol {
    let name: String
    let location: NSRange
    var `super`: COMethod? = nil

    override var description: String { return "(\(name), \(location))" }
    override var debugDescription: String { return "(\(self.description) -> \(self.super?.description ?? "(nil)"))" }

    init(name: String, location: NSRange = NSRange()) {
        self.name     = name
        self.location = location
    }

    required init?(coder aDecoder: NSCoder) {
        if let name = aDecoder.decodeObject(forKey: "n") as? String {
            self.name = name
        } else {
            return nil
        }

        if let location = aDecoder.decodeObject(forKey: "l") as? NSRange {
            self.location = location
        } else {
            return nil
        }
        self.super = aDecoder.decodeObject(forKey: "s") as? COMethod
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? SelectorPart {
            if self === object {
                return true
            }
            return object.name == self.name
        }
        return false
    }

    // protocol
    var fakename: String? = nil
    var oriname: String { return name }
}

extension SelectorPart: NSSecureCoding {
    static var supportsSecureCoding: Bool { return true }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "n")
        aCoder.encode(location, forKey: "l")
        aCoder.encode(`super`, forKey: "s")
    }
}

///////////////////////////////////////////////////////////////////// COMethod
class COMethod: NSObject, FakeProtocol {
    let method: String
    let location: NSRange
    fileprivate(set) var selectors = [SelectorPart]()

    init(name: String, location: NSRange = NSRange()) {
        self.method   = name
        self.location = location
    }

    required init?(coder aDecoder: NSCoder) {
        if let method = aDecoder.decodeObject(forKey: "m") as? String {
            self.method = method
        } else {
            return nil
        }

        if let ss = aDecoder.decodeObject(forKey: "ss") as? [SelectorPart] {
            self.selectors = ss
        } else {
            return nil
        }

        if let l = aDecoder.decodeObject(forKey: "l") as? NSRange {
            location = l
        } else {
            return nil
        }
    }

    // protocol
    var fakename: String? = nil
    var oriname: String { return method }

    override var description: String {
        let elements = selectors.map { $0.name }
        return "[\(elements.joined(separator: ":")):]"
    }

    override var debugDescription: String { return self.description }
}

extension COMethod: NSSecureCoding {
    static var supportsSecureCoding: Bool { return true }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(method, forKey: "m")
        aCoder.encode(selectors, forKey: "ss")
        aCoder.encode(location, forKey: "l")
    }
}

extension COMethod {
    func add(selector: SelectorPart) {
        selectors.append(selector)
    }

    func equalSelectors(to other: COMethod) -> Bool {
        return selectors == other.selectors
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? COMethod {
            if self === object {
                return true
            }
            return object.selectors == self.selectors
        }
        return false
    }

    func fake(with another: COMethod) {
        guard another !== self && self.selectors.count == another.selectors.count else { return }
        for idx in 0..<self.selectors.count {
            self.selectors[idx].fakename = another.selectors[idx].fakename
        }
    }
}

///////////////////////////////////////////////////////////////////// Clazz
class Clazz: NSObject, FakeProtocol {
    let classname: String
    var categoryname: String? = nil
    var supername: String?

    fileprivate(set) var properties = [COProperty]()
    fileprivate(set) var methods = [COMethod]()

    var fullpath: String? = nil

    init(classname: String, supername: String?) {
        self.classname = classname
        self.supername = supername
    }

    func add(property: COProperty) {
        properties.append(property)
    }

    func add(method: COMethod) {
        methods.append(method)
    }

    // protocol
    var fakename: String? = nil
    var oriname: String {
        if let category = categoryname {
            return "\(classname) (\(category))"
        }
        return classname
    }

    override var description: String {
        let classInfo: String
        if let category = categoryname {
            classInfo = "\(classname) (\(category))"
        } else {
            classInfo = "\(classname): \(supername ?? "")"
        }

        let propertyInfo: String
        if properties.count == 0 {
            propertyInfo = "()"
        } else {
            let elements = properties.map { $0.name }
            propertyInfo = "(@\(elements.joined(separator: ",@")))"
        }

        let methodInfo = methods.map { $0.description }.joined(separator: ",")
        return "{\nclass = \(classInfo);\nproperty = \(propertyInfo);\nmethod = \(methodInfo)}\n"
    }

    override var debugDescription: String { return self.description }
}
