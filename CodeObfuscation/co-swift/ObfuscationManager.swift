//
//  ObfuscationManager.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/7.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

public let __targetPathExtesion__ = "coh"
public var classRelationshipReg = [String: String]()

fileprivate let fakeCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_".cString(using: .utf8)
fileprivate var index: Int = 0

func registerClassRelationship(class: String, super: String) {
    classRelationshipReg[`class`] = `super`;
}

struct ObfuscationManager {
    fileprivate var fakeOffset = 0
    fileprivate var fakeSource = 0

    fileprivate let fm = FileManager.default
    fileprivate var analysisProducts = [FileAnalysis]()
    fileprivate var dbSavePath = ""
}

extension ObfuscationManager {
    mutating func goWithRootPath(_ rootpath: String) {
        if let absolutePath = Bundle.init(path: rootpath)?.bundlePath {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: absolutePath, isDirectory: &isDir) {
                if isDir.boolValue == false {
                    print("root path:\(absolutePath) is not a directory!")
                }
            } else {
                print("root path:\(absolutePath) is not exist!")
            }
            dbSavePath = absolutePath
            // 路径遍历开始
            self.runWithPath(absolutePath)
            self.saveToDatabase()
        }
    }

    private mutating func runWithPath(_ path: String) {
        do {
            let dirArray = try fm.contentsOfDirectory(atPath: path)
            let obfuscationFiles = Bundle.paths(forResourcesOfType: __targetPathExtesion__, inDirectory: path)

            for str in dirArray {
                let subPath = (path as NSString).appendingPathComponent(str) as String
                var isSubDir: ObjCBool = false
                fm.fileExists(atPath: subPath, isDirectory: &isSubDir)
                if isSubDir.boolValue == true {
                    self.runWithPath(subPath)
                }
            }

            for obfus in obfuscationFiles {
                self.analysisObfuscationWithPath(path, filename: (obfus as NSString).lastPathComponent as NSString)
            }
        } catch {
            print(error)
        }
    }

    private mutating func analysisObfuscationWithPath(_ path: String, filename: NSString) {
        let bd = Bundle.init(path: path)
        let identifier = filename.deletingPathExtension
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

        var obj = FileAnalysis.init(filepaths: paths, writtenFilepath: (path as NSString).appendingPathComponent(filename as String))
        obj.start()

        self.analysisProducts.append(obj)
    }

    private mutating func saveToDatabase() {
        self.formatClass()
        if fakeOffset == 0 {
            fakeOffset = Int(arc4random())
        }

        fakeSource = fakeOffset

        // Fake start
        for file in self.analysisProducts {
            self.fakeFile(file)
        }

        // 为避免real-name存在重复的情况，对全局real-name去重

        var relationship = [String: Object]()
        for file in self.analysisProducts {
            for (_, obj) in file.clazzs {
                for prop in obj.properties {
                    if let val = relationship[prop.name] {
                        prop.fakename = val.fakename
                    } else {
                        relationship[prop.name] = prop
                    }
                }
                for method in obj.methods {
                    for selector in method.selectors {
                        if let val = relationship[selector.name] {
                            selector.fakename = val.fakename
                        } else {
                            relationship[selector.name] = selector
                        }
                    }
                }
            }
        }

        let db = COObfuscationDatabase.init(databaseFilePath: dbSavePath,
                                            bundleIdentifier: Arguments.arguments.identifier,
                                            appVersion: Arguments.arguments.appVersion)
        for var file in self.analysisProducts {
            for (key, obj) in file.clazzs {
                let filename = (file.cohFilepath as NSString).lastPathComponent.replacingOccurrences(of: ".", with: "_")
                var type = COObfuscationType(rawValue: 0)
                if let _ = obj.categoryname {
                    type = COObfuscationType(rawValue: 1)
                }
                db.insertObfuscation(withFilename: filename,
                                     real: key,
                                     fake: obj.fakename!,
                                     location: "",
                                     type: type!)
                for prop in obj.properties {
                    db.insertObfuscation(withFilename: filename,
                                         real: prop.name!,
                                         fake: prop.fakename!,
                                         location: "",
                                         type: COObfuscationType(rawValue: 2)!);
                }
                for method in obj.methods {
                    for selector in method.selectors {
                        db.insertObfuscation(withFilename: filename,
                                             real: selector.name!,
                                             fake: selector.fakename!,
                                             location: "",
                                             type: COObfuscationType(rawValue: 3)!);
                    }
                }
            }
            file.write()
        }
    }

    private func formatClass() {
        for analysis in self.analysisProducts {
            for (_, obj) in analysis.clazzs {
                if let _ = obj.supername {
                    obj.supername = classRelationshipReg[obj.classname]
                }
            }
        }
    }

    private mutating func fakeFile(_ file: FileAnalysis) {
        for (_, obj) in file.clazzs {
            obj.fakename = self.getFakeStringRandomly()
            for prop in obj.properties {
                prop.fakename = self.getFakeStringRandomly()
            }
            for method in obj.methods {
                for sel in method.selectors {
                    sel.fakename = self.getFakeStringRandomly()
                }
            }
        }
    }

    private mutating func getFakeStringRandomly() -> String {
        index += 1
        let idx = arc4random() % 53
        fakeSource += 1
        let fake = String.init(format: "%c%lu%c",
                               fakeCharacters![index],
                               fakeSource,
                               fakeCharacters![Int.init(idx)])
        return fake
    }
}
