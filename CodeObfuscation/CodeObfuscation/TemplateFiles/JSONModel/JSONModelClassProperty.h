//
//  JSONModelClassProperty.h
//  JSONModel
//

#import <Foundation/Foundation.h>
#import "JSONModelClassProperty.coh"

/**
 * **You do not need to instantiate this class yourself.** This class is used internally by JSONModel
 * to inspect the declared properties of your model class.
 *
 * Class to contain the information, representing a class property
 * It features the property's name, type, whether it's a required property,
 * and (optionally) the class protocol
 */
@interface CO_CONFUSION_CLASS JSONModelClassProperty : NSObject

// deprecated
@property (assign, nonatomic) BOOL CO_CONFUSION_PROPERTY isIndex DEPRECATED_ATTRIBUTE;

/** The name of the declared property (not the ivar name) */
@property (copy, nonatomic) NSString *CO_CONFUSION_PROPERTY name;

/** A property class type  */
@property (assign, nonatomic) Class CO_CONFUSION_PROPERTY type;

/** Struct name if a struct */
@property (strong, nonatomic) NSString *CO_CONFUSION_PROPERTY structName;

/** The name of the protocol the property conforms to (or nil) */
@property (copy, nonatomic) NSString *CO_CONFUSION_PROPERTY protocol;

/** If YES, it can be missing in the input data, and the input would be still valid */
@property (assign, nonatomic) BOOL CO_CONFUSION_PROPERTY isOptional;

/** If YES - don't call any transformers on this property's value */
@property (assign, nonatomic) BOOL CO_CONFUSION_PROPERTY isStandardJSONType;

/** If YES - create a mutable object for the value of the property */
@property (assign, nonatomic) BOOL CO_CONFUSION_PROPERTY isMutable;

/** a custom getter for this property, found in the owning model */
@property (assign, nonatomic) SEL CO_CONFUSION_PROPERTY customGetter;

/** custom setters for this property, found in the owning model */
@property (strong, nonatomic) NSMutableDictionary *CO_CONFUSION_PROPERTY customSetters;

@end
