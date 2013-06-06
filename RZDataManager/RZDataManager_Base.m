//
//  RZDataManager_Base.m
//  RZDataManager-Demo
//
//  Created by Nick Donaldson on 5/28/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZDataManager_Base.h"
#import "NSObject+RZPropertyUtils.h"

@interface RZDataManager ()

- (NSException*)abstractMethodException:(SEL)selector;
- (NSException*)missingUniqueKeysExceptionWithObjectType:(NSString*)objectType;

@end

@implementation RZDataManager
{
    RZDataImporter * _dataImporter;
}

+ (instancetype)defaultManager
{
    static RZDataManager * s_defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_defaultManager = [[self alloc] init];
    });
    return s_defaultManager;
}

// Allocate data importer via lazy load
- (RZDataImporter*)dataImporter
{
    if (nil == _dataImporter){
        _dataImporter = [[RZDataImporter alloc] init];
        _dataImporter.dataManager = self;
    }
    return _dataImporter;
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSException*)abstractMethodException:(SEL)selector
{
    return [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(selector)]
                                 userInfo:nil];
}

- (NSException*)missingUniqueKeysExceptionWithObjectType:(NSString *)objectType
{
    return [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unable to find default ID key path in mapping for object type %@. Add \"Default ID Key\" to the mapping plist file", objectType]
                                 userInfo:nil];
}


#pragma mark - Data Manager public methods

- (id)objectOfType:(NSString*)type withValue:(id)value forKeyPath:(NSString*)keyPath createNew:(BOOL)createNew
{
    @throw [self abstractMethodException:_cmd];
}

- (id)objectOfType:(NSString*)type
         withValue:(id)value
        forKeyPath:(NSString*)keyPath
      inCollection:(id)collection
         createNew:(BOOL)createNew
{
    @throw [self abstractMethodException:_cmd];
}

- (id)objectsOfType:(NSString*)type matchingPredicate:(NSPredicate*)predicate
{
    @throw [self abstractMethodException:_cmd];
}

- (void)importData:(id)data objectType:(NSString*)type
           options:(NSDictionary *)options
        completion:(RZDataManagerImportCompletionBlock)completion
{
    @throw [self abstractMethodException:_cmd];
}


- (void)importData:(id)data objectType:(NSString *)type
   forRelationship:(NSString *)relationshipKey
          onObject:(id)otherObject
           options:(NSDictionary *)options
        completion:(RZDataManagerImportCompletionBlock)completion
{
    @throw [self abstractMethodException:_cmd];
}

- (void)importData:(id)data objectType:(NSString *)type
     dataIdKeyPath:(NSString *)dataIdKeyPath
    modelIdKeyPath:(NSString *)modelIdKeyPath
   forRelationship:(NSString *)relationshipKey
          onObject:(id)otherObject
        completion:(RZDataManagerImportCompletionBlock)completion
{
    @throw [self abstractMethodException:_cmd];
}

- (void)importInBackgroundUsingBlock:(RZDataManagerImportBlock)importBlock completion:(void (^)(NSError *))completionBlock
{
    @throw [self abstractMethodException:_cmd];
}

// optional, default does nothing
- (void)saveData:(BOOL)synchronous
{
    NSLog(@"RZDataManager: saveData: is not implemented.");
}

- (void)discardChanges
{
    NSLog(@"RZDataManager: discardChanges is not implemented.");
}

#pragma mark - Miscellaneous

- (NSDictionary*)dictionaryFromModelObject:(NSObject *)object
{
    RZDataManagerModelObjectMapping * mapping = [self.dataImporter mappingForClassNamed:NSStringFromClass([object class])];
    
    NSArray * propertyNames = [[object class] getPropertyNames];
    NSMutableDictionary * dictionaryRepresentation = [NSMutableDictionary dictionaryWithCapacity:propertyNames.count];
    
    // Introspected getters will not cause an ARC leak. Disable warning temporarily.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    [propertyNames enumerateObjectsUsingBlock:^(NSString * propName, NSUInteger idx, BOOL *stop) {
        
        NSString * propType = [[object class] dataTypeForPropertyNamed:propName];

        // TODO: For now this will only work if the getter name is not overridden. Need to handle that case in the future (in property utils).
        SEL getter = NSSelectorFromString(propName);
        
        if (![object respondsToSelector:getter]){
            NSLog(@"RZDataManger: Object of type %@ does not repsond to selector %@", NSStringFromClass([object class]), propName);
        }
        // To return a scalar data type, we need NSInvocation. The value will have to be converted to NSNumber for use in dictionary.
        else if (rz_isScalarDataType(propType))
        {
            
            NSNumber * numberValue = nil;
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[object methodSignatureForSelector:getter]];
            [invocation setSelector:getter];
            [invocation setTarget:object];
            
            if ([propType isEqualToString:kRZDataManagerTypeChar]){
                char charValue;
                [invocation setReturnValue:&charValue];
                [invocation invoke];
                numberValue = @(charValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeInt]){
                NSInteger intValue;
                [invocation setReturnValue:&intValue];
                [invocation invoke];
                numberValue = @(intValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeUnsignedInt]){
                NSUInteger uIntValue;
                [invocation setReturnValue:&uIntValue];
                [invocation invoke];
                numberValue = @(uIntValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeShort]){
                SInt16 shortValue;
                [invocation setReturnValue:&shortValue];
                [invocation invoke];
                numberValue = @(shortValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeUnsignedShort]){
                UInt16 uShortValue;
                [invocation setReturnValue:&uShortValue];
                [invocation invoke];
                numberValue = @(uShortValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeLong]){
                SInt32 longValue;
                [invocation setReturnValue:&longValue];
                [invocation invoke];
                numberValue = @(longValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeUnsignedLong]){
                UInt32 uLongValue;
                [invocation setReturnValue:&uLongValue];
                [invocation invoke];
                numberValue = @(uLongValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeLongLong]){
                SInt64 longLongValue;
                [invocation setReturnValue:&longLongValue];
                [invocation invoke];
                numberValue = @(longLongValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeUnsignedLongLong]){
                UInt64 uLongLongValue;
                [invocation setReturnValue:&uLongLongValue];
                [invocation invoke];
                numberValue = @(uLongLongValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeFloat]){
                float floatValue;
                [invocation setReturnValue:&floatValue];
                [invocation invoke];
                numberValue = @(floatValue);
            }
            else if ([propType isEqualToString:kRZDataManagerTypeDouble]){
                double doubleValue;
                [invocation setReturnValue:&doubleValue];
                [invocation invoke];
                numberValue = @(doubleValue);
            }
            
            if (nil != numberValue){
                [dictionaryRepresentation setObject:numberValue forKey:propName];
            }
        }
        else if ([mapping relationshipMappingForModelPropertyName:propName])
        {
            // for relationships, don't serialze the entire other object - this could lead to infinite recursion
            // just convert the unique identifier key/value pairs
            RZDataManagerModelObjectRelationshipMapping * relMapping = [mapping relationshipMappingForModelPropertyName:propName];
            RZDataManagerModelObjectMapping * otherObjMapping = [self.dataImporter mappingForClassNamed:relMapping.relationshipObjectType];
            
            id propValue = [object performSelector:getter];
            
            id (^IdSerializerBlock)(id obj) = ^id(id obj){
                
                id otherObjUid = nil;
                @try {
                    otherObjUid = [obj valueForKey:otherObjMapping.modelIdPropertyName];
                }
                @catch (NSException *exception) {
                    NSLog(@"RZDataImporter: Object of type %@ does not respond to key %@", relMapping.relationshipObjectType, otherObjMapping.modelIdPropertyName);
                }
                
                return otherObjUid;
                
            };
            
            if ([propValue isKindOfClass:[NSArray class]])
            {
                NSMutableArray * relArray = [NSMutableArray arrayWithCapacity:[propValue count]];
                [(NSArray*)propValue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                   
                    id otherObjUid = IdSerializerBlock(obj);
                    
                    if (otherObjUid){
                        [relArray addObject:@{otherObjMapping.dataIdKey : otherObjUid}];
                    }
                 
                }];
                
                [dictionaryRepresentation setObject:relArray forKey:propName];
            }
            else if ([propValue isKindOfClass:[NSSet class]])
            {
                NSMutableSet * relSet = [NSMutableSet setWithCapacity:[propValue count]];
                [(NSSet*)propValue enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    
                    id otherObjUid = IdSerializerBlock(obj);
                    
                    if (otherObjUid){
                        [relSet addObject:@{otherObjMapping.dataIdKey : otherObjUid}];
                    }
                    
                }];
                
                [dictionaryRepresentation setObject:relSet forKey:propName];

            }
            else
            {
                id otherObjUid = IdSerializerBlock(propValue);
                
                if (otherObjUid){
                    [dictionaryRepresentation setObject:@{otherObjMapping.dataIdKey : otherObjUid} forKey:propName];
                }
            }
        }
        else{
            id propValue = [object performSelector:getter];
            if (propValue){
                [dictionaryRepresentation setObject:propValue forKey:propName];
            }
        }
        
    }];
    
#pragma clang diagnostic pop
    
    return dictionaryRepresentation;
}

@end
