# code-obfuscation

A code obfuscation tool for iOS.

# Pre-Setting

Copy the directory [Obfuscation-Objective-C File.xctemplate](Obfuscation-Objective-C%20File.xctemplate) to `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/Source`, like below order:

```sh
sudo cp -r Obfuscation-Objective-C\ File.xctemplate/ /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File\ Templates/Source
```

Now, you can create obfuscation files in your projects. You might try to create them in your project, and then you will get 3 files.

# How to Use

Execute the order `./CodeObfuscation-release` or `./CodeObfuscation-debug` at your root path of your project.

> Also set the shell script at you Xcode project to exectue it. Alse see **Features**.

You could copy the program [CodeObfuscation-release](Products/iOS/CodeObfuscation-release) or [CodeObfuscation-debug](Products/iOS/CodeObfuscation-debug). Both are iOS platform.

# Obfuscation Syntax

- Add macro `CO_CONFUSION_CLASS` after keyword `@interface` and before classname. It tags the class is added to obfuscation task. e.g.

  ```objective-c
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject
  @end
  ```

- Also modify the category by `CO_CONFUSION_CATEGORY`. And the macro `CO_CONFUSION_CATEGORY` must be before category-name at bracket e.g.

  ```objective-c
  @interface NSString (CO_CONFUSION_CATEGORY abcde)
  @end
  ```

- Add macro `CO_CONFUSION_PROPERTY` before a property-name declared. It tags the property is added to obfuscation task. e.g.

  ```objective-c
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject

  @property (nonatomic, strong) NSString * CO_CONFUSION_PROPERTY prop1;
  @property CGFloat CO_CONFUSION_PROPERTY prop2;

  @end
  ```

  ​

- Add macro `CO_CONFUSION_METHOD` before a method head of declare or implementation. It tags the method is added to obfuscation task. e.g.

  ```objective-c
  // .h
  @interface CO_CONFUSION_CLASS COTemplateFile : NSObject

  CO_CONFUSION_METHOD
  - (void)makeFoo:(NSString *)foo1 arg2:(NSInteger)arg2;

  CO_CONFUSION_METHOD
  - (instancetype)initWithArg1:(CGFloat)arg, ...;

  @end

  // .m or .mm
  @implementation COTemplateFile

  CO_CONFUSION_METHOD
  - (void)_private:(NSString *)arg1 method:(float)arg2 scanned:(BOOL)scanned
  {
      ;
  }

  @end
  ```

# Features

##  Command Supported

- **-id \<path>** The directory of info.plist. Default is current executed path.
- **-offset \<unsigned integer>** The offset of obfuscation. Default is 0.
- **-release | -debug** It controls the macro `!defined(DEBUG)`. If release, the macro will be used.
- **-db \<path>** The directory of obfuscation database. Default is current executed path.
- **-root \<path>** The directory of project. Default is current executed path.
- **-super [--strict=\<true|false>]** Check the user-class' names which have been entranced obfuscation whethere exists in its super class or not. If exists, will info a warning. For **strict** option, will check all of classes of iOS Kits.
- **-st=\<true|false>** Strengthen the obfuscation. Default is true.
- **-help** Get the command (maybe, escaping…)) helpful info.
- **-version** Get the program supported iOS SDK version.



# Notice

- `CO_CONFUSION_CLASS` and `CO_CONFUSION_CATEGORY` is a prerequisite for `CO_CONFUSION_PROPERTY` and `CO_CONFUSION_METHOD`.
- **COULD NOT** use the code-obfuscation if your code contains runtime code. Unless you control it.

# License

The MIT License.

# TODO:

- Support @protocol.
- Convenience class' name getter.
- Property custome get-setter macro.
- Class and Method query command.
