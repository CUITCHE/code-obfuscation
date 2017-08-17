//
//  main.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/8/15.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

var manager = ObfuscationManager.init()
do {
    try manager.go(with: Arguments.arguments.rootpath as String)
} catch {
    print(error)
}
