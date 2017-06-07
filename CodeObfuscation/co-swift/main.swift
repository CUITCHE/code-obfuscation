//
//  main.swift
//  co-swift
//
//  Created by hejunqiu on 2017/6/6.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

print("Hello, World!")

var manager = ObfuscationManager.init()
manager.goWithRootPath(Arguments.arguments.rootpath)
print("END...")
