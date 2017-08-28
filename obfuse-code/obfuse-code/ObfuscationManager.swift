//
//  ObfuscationManager.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/8/16.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate let fakeCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_".characters.map{ return $0 }

fileprivate extension String {
    static let __targetPathExtesion__ = "coh"
}

fileprivate var classRelationshipReg = [String: String]()
fileprivate var g_clazzs = [String: Clazz]()

func registerClassRelationship(classname: String, super: String, clazz: Clazz) {
    classRelationshipReg[classname] = `super`
    if clazz.categoryname == nil {
        g_clazzs[classname] = clazz
    }
}

struct ObfuscationManager {
    fileprivate static var index = 0
    enum ObfuscationManagerError: Error {
        case generic(code: Int, message: String)
    }
    fileprivate var fakeSource = 0
    fileprivate var obfuscationFilesCount = 0
    fileprivate var rate = 0

    fileprivate var analysisProducts = [FileAnalysis]()
    fileprivate var dbSavePath = ""
    fileprivate let imageCache = CacheImage.init()

    mutating func go(with rootpath: String) throws {
        if let absolutepath = Bundle.init(path: rootpath)?.bundlePath {
            var isDir: ObjCBool = .init(false)
            guard FileManager.default.fileExists(atPath: absolutepath, isDirectory: &isDir) else {
                throw ObfuscationManagerError.generic(code: 1, message: "root path:\(absolutepath) is not exist!")
            }
            guard isDir.boolValue else {
                throw ObfuscationManagerError.generic(code: 2, message: "root path:\(absolutepath) is not a directory!")
            }
            dbSavePath = absolutepath
            try self._run(with: absolutepath)
            self._saveToDatabase()
        } else {
            throw ObfuscationManagerError.generic(code: 1, message: "root path:\(rootpath) is not exist!")
        }
    }
}

fileprivate extension ObfuscationManager {
    mutating func _run(with path: String) throws {
        let dirArray = try FileManager.default.contentsOfDirectory(atPath: path)
        let obfuscationFiles = Bundle.paths(forResourcesOfType: .__targetPathExtesion__, inDirectory: path)

        for str in dirArray {
            let subPath = (path as NSString).appendingPathComponent(str)
            var isSubDir: ObjCBool = .init(false)
            FileManager.default.fileExists(atPath: subPath, isDirectory: &isSubDir)
            if isSubDir.boolValue {
                try self._run(with: subPath)
            }
        }
        for obfus in obfuscationFiles {
            self._analysisObfuscation(with: path, filename: (obfus as NSString).lastPathComponent)
        }
    }

    mutating func _analysisObfuscation(with path: String, filename: String) {
        let bd = Bundle.init(path: path)
        let identifier = (filename as NSString).deletingPathExtension
        var paths = [String]()
        // 尝试读取.h文件
        if let filepath = bd?.path(forResource: identifier, ofType: "h") {
            paths.append(filepath)
        }
        // 尝试读取.m文件
        if let filepath = bd?.path(forResource: identifier, ofType: "m") {
            paths.append(filepath)
        }
        // 尝试读取.mm文件
        if let filepath = bd?.path(forResource: identifier, ofType: "mm") {
            paths.append(filepath)
        }
        let fileAnalysiser = FileAnalysis.init(filepaths: paths, written: (path as NSString).appendingPathComponent(filename))
        fileAnalysiser.start()
        self.analysisProducts.append(fileAnalysiser)
    }

    mutating func _saveToDatabase() {
        // 整理class
        self._formatClass()
        self.fakeSource = Int(Arguments.arguments.obfuscationOffset)
        // Fake start
        self._fakename()
        self._distinct()
        self._superCheck()

        if let db = ObfuscationDatabase.init(filepath: dbSavePath, bundleIdentifier: Arguments.arguments.identifier, appVersion: Arguments.arguments.appVersion) {
            for file in self.analysisProducts {
                let filename = (file.cohFilepath as NSString).lastPathComponent.replacingOccurrences(of: ".", with: "_")
                for (key, obj) in file.clazzs {
                    db.insert(filename: filename, real: key, fake: obj.fakename!.appending("$\(Arguments.arguments.identifier)"), type: obj.categoryname == nil ? .class: .category)
                    for prop in obj.properties {
                        db.insert(filename: filename, real: prop.name, fake: prop.fakename!, type: .property)
                    }
                    for method in obj.methods {
                        for sel in method.selectors {
                            db.insert(filename: filename, real: sel.name, fake: sel.fakename!, type: .method)
                        }
                    }
                }
                for (key, obj) in file.protocols {
                    db.insert(filename: filename, real: key, fake: obj.fakename!, type: .protocol)
                    for prop in obj.properties {
                        db.insert(filename: filename, real: prop.name, fake: prop.fakename!, type: .property)
                    }
                    for method in obj.methods {
                        for sel in method.selectors {
                            db.insert(filename: filename, real: sel.name, fake: sel.fakename!, type: .method)
                        }
                    }
                }
                file.write()
            }
        }
    }

    // 为避免real-name存在重复的情况，对全局real-name去重
    func _distinct() {
        var relationship = [String: FakeProtocol]()
        for file in self.analysisProducts {
            for (_, obj) in file.clazzs {
                var val: FakeProtocol? = nil
                for prop in obj.properties {
                    val = relationship[prop.name]
                    if let val = val {
                        prop.fakename = val.fakename
                    } else {
                        relationship[prop.name] = prop
                    }
                }
                for method in obj.methods {
                    for sel in method.selectors {
                        val = relationship[sel.name]
                        if let val = val {
                            sel.fakename = val.fakename
                        } else {
                            relationship[sel.name] = sel
                        }
                    }
                }
            }
            for (_, obj) in file.protocols {
                var val: FakeProtocol? = nil
                for prop in obj.properties {
                    val = relationship[prop.name]
                    if let val = val {
                        prop.fakename = val.fakename
                    } else {
                        relationship[prop.name] = prop
                    }
                }
                for method in obj.methods {
                    for sel in method.selectors {
                        val = relationship[sel.name]
                        if let val = val {
                            sel.fakename = val.fakename
                        } else {
                            relationship[sel.name] = sel
                        }
                    }
                }
            }
        }
    }

    func _superCheck() {
        guard Arguments.arguments.supercheck else { return }
        printc.println(text: "User: check user's class...")
        for file in self.analysisProducts {
            for (key, obj) in file.clazzs {
                guard obj.categoryname == nil else { continue }
                let superclass = g_clazzs[obj.supername ?? ""]
                guard superclass != nil else { continue }
                for method in obj.methods {
                    for supermethod in superclass!.methods {
                        if method.isEqual(supermethod) {
                            method.fake(with: supermethod)
                            printc.println(text: "[Warning]: (\(key),\(superclass!.classname)), duplicate method: \(method.method). Fixed the fake name by super's", marks: .yellow)
                        }
                    }
                }
                
            }
        }
        guard Arguments.arguments.strict else { return }
        printc.println(text: "User: check iOS Kits classes. This operation may need more time...")
        for file in self.analysisProducts {
            for (key, obj) in file.clazzs {
                for user in obj.methods {
                    if obj.supername == nil {
                        obj.supername = classRelationshipReg[obj.classname]
                        if obj.supername == nil {
                            obj.supername = self.imageCache.getSuperName(withClassname: obj.classname)
                        }
                        if obj.supername == nil {
                            printc.println(text: "[Error]: \(obj.classname) is not exists in cache image. Check your SDK Version(\(self.imageCache.imageVersion.description)).", marks: .Red, .white)
                            exit(1)
                        }
                    }
                    if self.imageCache.search(user, withSuperName: obj.supername!) {
                        printc.println(text: "[Warning]: (\(key),\(obj.supername!)), You can't OBFUSE the system method: \(user.method). You should remove method tag before the method.", marks: .yellow)
                    }
                }
            }
        }
    }

    func _formatClass() {
        for file in self.analysisProducts {
            for (_, obj) in file.clazzs {
                if obj.supername == nil {
                    obj.supername = classRelationshipReg[obj.classname]
                }
            }
        }
    }

    mutating func _fake(with file: FileAnalysis) {
        for (_, obj) in file.clazzs {
            obj.fakename = self._obtainFakeStringRandomly()
            for prop in obj.properties {
                prop.fakename = self._obtainFakeStringRandomly()
            }
            for method in obj.methods {
                for sel in method.selectors {
                    sel.fakename = self._obtainFakeStringRandomly()
                }
            }
            for (_, obj) in file.protocols {
                obj.fakename = self._obtainFakeStringRandomly()
                for prop in obj.properties {
                    prop.fakename = self._obtainFakeStringRandomly()
                }
                for method in obj.methods {
                    for sel in method.selectors {
                        sel.fakename = self._obtainFakeStringRandomly()
                    }
                }
            }
        }
    }

    mutating func _strengthenObfuscation() {
        var readyFakes = [FakeProtocol]()
        for file in self.analysisProducts {
            for (_, obj) in file.clazzs {
                readyFakes.append(obj)
                for prop in obj.properties {
                    readyFakes.append(prop)
                }
                for method in obj.methods {
                    for sel in method.selectors {
                        readyFakes.append(sel)
                    }
                }
            }
            for (_, obj) in file.protocols {
                readyFakes.append(obj)
                for p in obj.properties {
                    readyFakes.append(p)
                }
                for m in obj.methods {
                    for sel in m.selectors {
                        readyFakes.append(sel)
                    }
                }
            }
        }
        readyFakes.sort { (_,_) in return arc4random() % 37 < 19 }
        for var val in readyFakes {
            val.fakename = self._obtainFakeStringRandomly()
        }
    }

    mutating func _fakename() {
        if Arguments.arguments.st {
            self._strengthenObfuscation()
        } else {
            for file in self.analysisProducts {
                self._fake(with: file)
            }
        }
    }

    mutating func _obtainFakeStringRandomly() -> String {
        let str = "\(fakeCharacters[26 + ObfuscationManager.index % 26])\(fakeCharacters[ObfuscationManager.index % 53])\(fakeSource)\(fakeCharacters[Int(arc4random() % 53)])"
        ObfuscationManager.index += 1
        fakeSource = fakeSource &+ 1
        return str
    }
}
