//
//  RZDataImporter.h
//
//  Created by Nick Donaldson on 2/26/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZDataManagerModelObject.h"
#import "RZDataManagerModelObjectMapping.h"

@class RZDataManager;
@class RZDataImporterDiffInfo;

@interface RZDataImporter : NSObject

//! Weak reference to parent Data Manager
@property (nonatomic, weak) RZDataManager *dataManager;

//! Set to override on importer-level whether should decode HTML entities from strings (defaults to NO)
@property (nonatomic, assign) BOOL shouldDecodeHTML;

//! Set to override ISO (UTC) standard date format for all NSDate conversions from strings
@property (nonatomic, strong) NSString *defaultDateFormat;

//! Externally get the mapping for a particular class or entity
- (RZDataManagerModelObjectMapping*)mappingForClassNamed:(NSString*)className;

//! Import data from a dictionary to an object conforming to RZDataManagerModelObject protocol
- (void)importData:(NSDictionary*)data toObject:(NSObject<RZDataManagerModelObject>*)object;
- (void)importData:(NSDictionary*)data toObject:(NSObject<RZDataManagerModelObject>*)object usingMapping:(RZDataManagerModelObjectMapping*)mapping;

// TODO: Reimplement this

////! Return array of indices for objects that have been inserted, deleted, or moved, based on passed-in object array and data array. Basically calculates diff-update info of model object collection with incoming data set.
///*!
//    objects - array of objects to update. Should be of type objClass.
//    data - either an array of dictionaries or a dictionary containing data with which to update objects
//    dataIdKeyPath - key path to value uniquely identifying object in raw dictionary
//    modelIdKeyPath - key path to value uniquely identifying model object. Value will be compared against value for dataIdKey in raw data
//*/
//- (RZDataImporterDiffInfo*)diffInfoForObjects:(NSArray*)objects
//                                     withData:(id)data
//                                dataIdKeyPath:(NSString*)dataIdKeyPath
//                               modelIdKeyPath:(NSString*)modelIdKeyPath;


@end


@interface RZDataImporterDiffInfo : NSObject

// Indices at which new objects are present in data array
@property (strong, nonatomic) NSMutableArray* insertedObjectIndices;

// Indices in the object array of objects that should be removed (not present in data array)
@property (strong, nonatomic) NSMutableArray* removedObjectIndices;

// Indices for objects that have moved (the indices in the data array, which represent the final index of the object after the update)
@property (strong, nonatomic) NSMutableArray* movedObjectIndices;

@end