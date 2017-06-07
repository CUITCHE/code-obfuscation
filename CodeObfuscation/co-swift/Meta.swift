//
//  Meta.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

public class Object {
    private(set) public var name : String!

    public var fakename : String?

    init(name : String) {
        self.name = name
    }
}

final class Property : Object {

}

final class Selector : Object {

}

final class Method : Object {
    public var selectors = [Selector]()
}

final class Class {
    public let classname: String!
    public var supername: String?
    public var categoryname: String?
    public var fakename: String?

    public var properties = [Property]()
    public var methods = [Method]()

    init(classname : String, supername : String?) {
        self.classname = classname
        self.supername = supername
    }

    func addProperty(_ prop : Property) {
        self.properties.append(prop)
    }

    func addMethod(_ method : Method) {
        self.methods.append(method)
    }
}
