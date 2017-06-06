//
//  Object.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

public class Object {
    private let _name : String!

    public var fakename : String?
    public var name : String! {
        get {
            return _name
        }
    }
    init(name : String) {
        self._name = name
    }
}
