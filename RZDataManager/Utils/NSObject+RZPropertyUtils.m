//
//  NSObject+RZPropertyUtils.m
//  RZDataManager-Demo
//
//  Created by Nick Donaldson on 5/30/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//
// 

#import "NSObject+RZPropertyUtils.h"
#import <objc/runtime.h>

// Constants intended for types that typically come up when importing data (NSManagedObject or otherwise)

NSString *const kRZDataTypeNSArray          = @"NSArray";
NSString *const kRZDataTypeNSDictionary     = @"NSDictionary";
NSString *const kRZDataTypeNSSet            = @"NSSet";
NSString *const kRZDataTypeNSOrderedSet     = @"NSOrderedSet";
NSString *const kRZDataTypeNSString         = @"NSString";
NSString *const kRZDataTypeNSDate           = @"NSDate";
NSString *const kRZDataTypeNSNumber         = @"NSNumber";
NSString *const kRZDataTypeUnsignedChar     = @"unsigned char";
NSString *const kRZDataTypeChar             = @"char";
NSString *const kRZDataTypeShort            = @"short";
NSString *const kRZDataTypeUnsignedShort    = @"unsigned short";
NSString *const kRZDataTypeInt              = @"int";
NSString *const kRZDataTypeUnsignedInt      = @"unsigned int";
NSString *const kRZDataTypeLong             = @"long";
NSString *const kRZDataTypeUnsignedLong     = @"unsigned long";
NSString *const kRZDataTypeLongLong         = @"long long";
NSString *const kRZDataTypeUnsignedLongLong = @"unsigned long long";
NSString *const kRZDataTypeFloat            = @"float";
NSString *const kRZDataTypeDouble           = @"double";

// Scalar type names
static NSArray *scalarTypeNames = nil;

__attribute__((constructor))
static void initialize_rzScalarTypeNames()
{
    scalarTypeNames = @[kRZDataTypeChar,
            kRZDataTypeDouble,
            kRZDataTypeFloat,
            kRZDataTypeInt,
            kRZDataTypeLong,
            kRZDataTypeLongLong,
            kRZDataTypeShort,
            kRZDataTypeUnsignedChar,
            kRZDataTypeUnsignedInt,
            kRZDataTypeUnsignedLong,
            kRZDataTypeUnsignedLongLong,
            kRZDataTypeUnsignedShort];
}

__attribute__((destructor))
static void destroy_rzScalarTypeNames()
{
    scalarTypeNames = nil;
}

BOOL rz_isScalarDataType(NSString *rzTypeName)
{
    return [scalarTypeNames containsObject:rzTypeName];
}

static NSDictionary *rz_TypeMappings = nil;

// Statically allocate lookup dictionary for efficinent lookup of objc scalar type mappings to string constants
__attribute__((constructor))
static void initialize_rzTypeMappings()
{
    rz_TypeMappings = @{
            @"f" : kRZDataTypeFloat,
            @"d" : kRZDataTypeDouble,
            @"i" : kRZDataTypeInt,
            @"I" : kRZDataTypeUnsignedInt,
            @"s" : kRZDataTypeShort,
            @"S" : kRZDataTypeUnsignedShort,
            @"l" : kRZDataTypeLong,
            @"L" : kRZDataTypeUnsignedLong,
            @"q" : kRZDataTypeLongLong,
            @"Q" : kRZDataTypeUnsignedLongLong,
            @"c" : kRZDataTypeChar,
            @"C" : kRZDataTypeUnsignedChar
    };
}

__attribute__((destructor))
static void destroy_rzTypeMappings()
{
    rz_TypeMappings = nil;
}


static objc_property_t RZGetProperty(NSString *name, Class class)
{
    objc_property_t property = class_getProperty(class, [name UTF8String]);
    if (property == NULL)
    {
        // check base classes
        Class baseClass = class_getSuperclass(class);
        while (baseClass != nil && property == NULL)
        {
            property  = class_getProperty(baseClass, [name UTF8String]);
            baseClass = class_getSuperclass(baseClass);
        }
    }

    return property;
}


@implementation NSObject (RZPropertyUtils)

+ (BOOL)rz_hasPropertyNamed:(NSString *)propertyName
{
    return RZGetProperty(propertyName, [self class]) != NULL;
}

+ (NSArray *)rz_getPropertyNames
{
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);

    NSMutableArray *names = [NSMutableArray array];

    for (unsigned int i = 0; i < count; i++)
    {

        objc_property_t property = properties[i];
        [names addObject:[NSString stringWithUTF8String:property_getName(property)]];
    }

    // Add properties from base classes
    Class baseClass = class_getSuperclass([self class]);
    while (baseClass != nil)
    {
        [names addObjectsFromArray:[baseClass rz_getPropertyNames]];
        baseClass = class_getSuperclass(baseClass);
    }
    
    free(properties);

    return names;
}

+ (NSString *)rz_dataTypeForPropertyNamed:(NSString *)propertyName
{
    static NSMutableDictionary *s_dataTypeCache = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_dataTypeCache = [[NSMutableDictionary alloc] init];
    });
    
    NSString *key = [NSStringFromClass([self class]) stringByAppendingPathExtension:propertyName];
    
    NSString *typenameString = [s_dataTypeCache objectForKey:key];
    
    if (nil == typenameString)
    {
        objc_property_t property = RZGetProperty(propertyName, [self class]);
        const char *propAttrString = property_getAttributes(property);

        if (propAttrString != NULL)
        {

            NSString *propString = [NSString stringWithUTF8String:propAttrString];

            NSScanner *scanner = [NSScanner scannerWithString:propString];
            [scanner setCaseSensitive:YES];
            [scanner setCharactersToBeSkipped:nil];

            // Type is first part of property string, no need to split components
            if ([scanner scanString:@"T" intoString:NULL])
            {
                [scanner scanUpToString:@"," intoString:&typenameString];
                typenameString = [typenameString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
            }
        }

        if (typenameString)
        {
            NSString *mappedType = [rz_TypeMappings objectForKey:typenameString];
            if (mappedType)
            {
                typenameString = mappedType;
            }
            
            [s_dataTypeCache setObject:typenameString forKey:key];
        }
    }

    return typenameString;
}

+ (SEL)rz_getterForPropertyNamed:(NSString *)propertyName
{
    __block NSString *getterString = nil;
    objc_property_t property = RZGetProperty(propertyName, [self class]);
    const char *propAttrString = property_getAttributes(property);

    if (propAttrString != NULL)
    {

        getterString = propertyName;

        NSString *propString     = [NSString stringWithUTF8String:propAttrString];
        NSArray  *propComponents = [propString componentsSeparatedByString:@","];
        [propComponents enumerateObjectsUsingBlock:^(NSString *c, NSUInteger idx, BOOL *stop)
        {
            if ([c characterAtIndex:0] == 'G')
            {
                getterString = [c substringFromIndex:1];
                *stop = YES;
            }
        }];
    }

    return getterString ? NSSelectorFromString(getterString) : nil;
}

+ (SEL)rz_setterForPropertyNamed:(NSString *)propertyName
{
    __block NSString *setterString = nil;
    objc_property_t property = RZGetProperty(propertyName, [self class]);
    const char *propAttrString = property_getAttributes(property);

    if (propAttrString != NULL)
    {

        NSString *propString     = [NSString stringWithUTF8String:propAttrString];
        NSArray  *propComponents = [propString componentsSeparatedByString:@","];
        [propComponents enumerateObjectsUsingBlock:^(NSString *c, NSUInteger idx, BOOL *stop)
        {
            if ([c characterAtIndex:0] == 'S')
            {
                setterString = [c substringFromIndex:1];
                *stop = YES;
            }
        }];

        if (setterString == nil)
        {
            setterString = [NSString stringWithFormat:@"set%@:", [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] capitalizedString]]];
        }
    }

    return setterString ? NSSelectorFromString(setterString) : nil;
}

@end
