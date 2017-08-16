//
//  FileAnalysis.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/8/15.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate extension String {
    static let __scanTagString__ = "CO_CONFUSION_"
    static let __method__        = "METHOD"
    static let __property__      = "PROPERTY"
}

class FileAnalysis {
    enum FileAnalysisError: Error {
        case codeExistsError(code: Int)
        case generic(code: Int, message: String)
    }
    fileprivate let filepaths: [String]
    let cohFilepath: String
    fileprivate(set) var clazzs = [String: Clazz]()

    fileprivate var outStream: FileOutStream

    init(filepaths: [String], written targetpath: String) {
        self.filepaths = filepaths
        self.cohFilepath = targetpath
        if let obj = FileOutStream.init(filepath: targetpath) {
            self.outStream = obj
        } else {
            exit(-1)
        }
    }

    func start() {
        outStream.read()
        for filepath in self.filepaths {
            do {
                let filecontent = try String.init(contentsOfFile: filepath)
                if self.outStream.worth(parsing: filecontent, filename: (filepath as NSString).lastPathComponent) {
                    try self._analysisClass(with: filecontent)
                }
            } catch {
                print(error)
                continue
            }
        }
    }

    func write() {
        guard self.outStream.needGenerateObfuscationCode else { return }
        self.outStream.begin()
        for (_, value) in self.clazzs {
            var dict = [String: String]()
            dict[value.categoryname ?? value.classname] = value.fakename ?? ""
            for prop in value.properties {
                dict[prop.name] = prop.fakename ?? ""
            }
            for method in value.methods {
                for sel in method.selectors {
                    dict[sel.name] = sel.fakename ?? ""
                }
            }
            self.outStream.write(obfuscation: dict)
        }
        self.outStream.end()
    }
}

fileprivate extension FileAnalysis {

    func _analysisClass(with classString: String) throws {
        var scanner = Scanner.init(string: classString)
        scanner.charactersToBeSkipped = .whitespacesAndNewlines
        var scannedString = [String]()
        var scannedRange = NSMakeRange(0, 0)

        while scanner.scanUpTo("@interface", into: nil) {
            scannedRange.location = scanner.scanLocation
            if scanner.scanUpTo("CO_CONFUSION_CLASS", into: nil) == false {
                continue
            }
            scanner.scanString("CO_CONFUSION_CLASS", into: nil)
            var className: NSString? = nil
            if scanner.scanUpTo(":", into: &className) { // 类首次声明
                scanner.scanString(":", into: nil)
                var superName: NSString? = nil
                if scanner.scanUpToCharacters(from: .whitespacesAndNewlines, into: &superName) == false {
                    throw FileAnalysisError.codeExistsError(code: 1)
                }
                let classname = className!.trimmingCharacters(in: .whitespacesAndNewlines)
                let clazz = Clazz.init(classname: classname, supername: superName as String?)
                let location_start = scanner.scanLocation
                scanner.scanUpTo("@end", into: nil)
                let classDeclaredString = (classString as NSString).substring(with: NSMakeRange(location_start, scanner.scanLocation - location_start))
                try self._analysisFile(with: classDeclaredString, into: clazz, methodFlag: ";")
                self.clazzs[classname] = clazz

                // registerClassRelationship(className, superName, clazz);

                scanner.scanString("@end", into: nil)
                scannedRange.length = scanner.scanLocation - scannedRange.location
                scannedString.append((classString as NSString).substring(with: scannedRange))
            }
        }

        let restString = NSMutableString.init(string: classString)
        for str in scannedString {
            restString.replaceOccurrences(of: str, with: "", options: .anchored, range: NSMakeRange(0, restString.length))
        }
        scanner = Scanner.init(string: restString as String)

        // 扫描类别和扩展
        while scanner.scanUpTo("@interface", into: nil) && scanner.isAtEnd == false {
            scanner.charactersToBeSkipped = .whitespacesAndNewlines
            scanner.scanString("@interface", into: nil)
            var className: NSString? = nil
            if scanner.scanUpTo("(", into: &className) {
                if scanner.scanUpTo("CO_CONFUSION_CATEGORY", into: nil) == false {
                    continue
                }
                scanner.scanString("CO_CONFUSION_CATEGORY", into: nil)
                let classname = className!.trimmingCharacters(in: .whitespacesAndNewlines)
                var category: NSString? = nil
                var clazz: Clazz? = nil
                if scanner.scanUpTo(")", into: &category) {
                    if category!.length == 0 { // 这是扩展。扩展必须从已有的分析的字典里取；否则报错
                        clazz = self.clazzs[classname]
                        if clazz == nil {
                            print("category(\(classname)): no such class.")
                            exit(-1)
                        }
                    } else { // 这是类别。类别可以自建分析内容
                        let identifier = "\(classname) (\(category!))"
                        clazz = self.clazzs[identifier]
                        if clazz == nil {
                            clazz = Clazz.init(classname: classname, supername: nil)
                            clazz?.categoryname = category as String?
                            self.clazzs[identifier] = clazz!
                        }
                    }
                }
                if let clazz = clazz {
                    let location_start = scanner.scanLocation
                    scanner.scanUpTo("@end", into: nil)
                    let classDeclaredString = restString.substring(with: NSMakeRange(location_start, scanner.scanLocation - location_start))
                    try self._analysisFile(with: classDeclaredString, into: clazz, methodFlag: ";")
                    scanner.scanString("@end", into: nil)
                }
            }
            scanner.charactersToBeSkipped = nil
        }
        // implementation 分析
        scanner = Scanner.init(string: classString)
        let implementationFlag = CharacterSet.init(charactersIn: "-+@(\n \t")
        while scanner.scanUpTo("@implementation", into: nil) && scanner.isAtEnd == false {
            scanner.scanString("@implementation", into: nil)
            var className: NSString? = nil
            if scanner.scanUpToCharacters(from: implementationFlag, into: &className) == false {
                continue
            }
            var category: String? = nil
            var categoryRange = NSMakeRange(NSNotFound, 0)
            let cs = classString as NSString
            for idx in scanner.scanLocation..<cs.length {
                let ch = cs.character(at: idx)
                if ch == unichar(" ") || ch == unichar("\n") {
                    continue
                }
                if ch == unichar("(") {
                    categoryRange.location = idx + 1
                } else if ch == unichar(")") {
                    categoryRange.length = idx - categoryRange.location
                    category = cs.substring(with: categoryRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                } else {
                    if categoryRange.location == NSNotFound {
                        break
                    }
                }
            }
            var clazz: Clazz? = nil
            if let category = category {
                if category.characters.count == 0 {
                    clazz = self.clazzs[className! as String]
                } else {
                    let identifier = "\(className! as String) (\(category))"
                    clazz = self.clazzs[identifier]
                }
            }
            if clazz == nil {
                throw FileAnalysisError.codeExistsError(code: -1)
            }
            let location_start = scanner.scanLocation
            scanner.scanUpTo("@end", into: nil)
            let classDeclaredString = restString.substring(with: NSMakeRange(location_start, scanner.scanLocation - location_start))
            try self._analysisFile(with: classDeclaredString, into: clazz!, methodFlag: "{")
        }
    }

    /* 该方法传入的是整个文件(.h, .m, .mm)的内容
     * 属性混淆实例：@property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
     * 方法混淆实例：
     * CO_CONFUSION_METHOD
     * - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;
     */
    func _analysisFile(with fileString: String, into clazz: Clazz, methodFlag: String) throws {
        let scanner = Scanner.init(string: fileString)
        var string: NSString? = nil
        var methodPropertyScannedTag = CharacterSet.init(charactersIn: "+-")
        methodPropertyScannedTag.formUnion(.whitespacesAndNewlines)
        while scanner.scanUpTo(.__scanTagString__, into: &string) && scanner.isAtEnd == false {
            scanner.scanString(.__scanTagString__, into: nil)
            // 扫描property或者method
            string = nil
            scanner.scanUpToCharacters(from: methodPropertyScannedTag, into: &string)
            if string!.isEqual(to: .__property__) {
                var property: NSString? = nil
                if scanner.scanUpTo(";", into: &property) {
                    let range = property!.range(of: " ")
                    if range.location != NSNotFound {
                        if range.location == 0 {
                            throw FileAnalysisError.generic(code: -77, message: "scanning property occurs error: \(property!)")
                        } else {
                            property = property?.substring(to: range.location - 1) as NSString?
                        }
                    }
                    clazz.add(property: COProperty.init(name: property! as String, location: NSMakeRange(scanner.scanLocation - property!.length, property!.length)))
                }
            } else if string!.isEqual(to: .__method__) {
                var method: NSString? = nil
                if scanner.scanUpTo(methodFlag, into: &method) && scanner.isAtEnd == false {
                    clazz.add(method: COMethod.init(name: method! as String, location: NSMakeRange(scanner.scanLocation - method!.length, method!.length)))
                    try self._analysisMethod(with: method!.trimmingCharacters(in: .whitespacesAndNewlines), into: clazz.methods.last!)
                }
            }
        }
    }

    // example: - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2 :(NSString *)arg3
    func _analysisMethod(with methodString: String, into method: COMethod) throws {
        let scanner = Scanner.init(string: methodString)
        // 找到第一个selector
        var selector: NSString? = nil
        scanner.scanUpTo(")", into: nil)
        scanner.scanLocation += 1
        scanner.charactersToBeSkipped = .whitespacesAndNewlines
        scanner.scanUpTo(":", into: &selector)
        guard selector != nil else { throw FileAnalysisError.codeExistsError(code: -2) }
        scanner.charactersToBeSkipped = nil
        method.add(selector: SelectorPart.init(name: selector! as String, location: NSMakeRange(scanner.scanLocation - selector!.length, selector!.length)))
        // 找余下的selector
        while scanner.scanUpTo(")", into: nil) && scanner.isAtEnd == false {
            scanner.scanString(")", into: nil)
            scanner.charactersToBeSkipped = .whitespacesAndNewlines
            scanner.scanUpToCharacters(from: .whitespacesAndNewlines, into: nil)
            if scanner.scanUpTo(":", into: &selector) && scanner.isAtEnd == false {
                method.add(selector: SelectorPart.init(name: selector! as String, location: NSMakeRange(scanner.scanLocation - selector!.length, selector!.length)))
            }
            scanner.charactersToBeSkipped = nil
        }
    }
}
