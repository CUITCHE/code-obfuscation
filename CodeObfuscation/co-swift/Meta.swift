//
//  Meta.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

final class Property : Object {

}

final class Selector : Object {

}

final class Method : Object {
    public let selectors = [Selector]()
}

struct Class {
    public let classname : String!
    public let supername : String?
    public var categoryname : String?

    public var properties = [Property]()
    public var methods = [Method]()

    init(classname : String, supername : String?) {
        self.classname = classname
        self.supername = supername
    }

    mutating func addProperty(_ prop : Property) {
        self.properties.append(prop)
    }

    mutating func addMethod(_ method : Method) {
        self.methods.append(method)
    }
}
