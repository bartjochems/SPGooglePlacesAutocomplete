//
//  SPGooglePlacesAutocompletePlace.m
//  SPGooglePlacesAutocomplete
//
//  Created by Stephen Poletto on 7/17/12.
//  Copyright (c) 2012 Stephen Poletto. All rights reserved.
//

#import "SPGooglePlacesAutocompletePlace.h"
#import "SPGooglePlacesPlaceDetailQuery.h"

@interface SPGooglePlacesAutocompletePlace()
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) SPGooglePlacesAutocompletePlaceType type;
@end

@implementation SPGooglePlacesAutocompletePlace

+ (SPGooglePlacesAutocompletePlace *)placeFromDictionary:(NSDictionary *)placeDictionary apiKey:(NSString *)apiKey
{
    SPGooglePlacesAutocompletePlace *place = [[self alloc] init];
    place.name = placeDictionary[@"description"];
    place.reference = placeDictionary[@"reference"];
    place.identifier = placeDictionary[@"id"];
    place.type = SPPlaceTypeFromDictionary(placeDictionary);
    place.key = apiKey;
    return place;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Name: %@, Reference: %@, Identifier: %@, Type: %@",
            self.name, self.reference, self.identifier, SPPlaceTypeStringForPlaceType(self.type)];
}

- (CLGeocoder *)geocoder {
    if (!geocoder) {
        geocoder = [[CLGeocoder alloc] init];
    }
    return geocoder;
}

- (void)resolveEstablishmentPlaceToPlacemark:(SPGooglePlacesPlacemarkResultBlock)block {
    SPGooglePlacesPlaceDetailQuery *query = [[SPGooglePlacesPlaceDetailQuery alloc] initWithApiKey:self.key];
    query.reference = self.reference;
    [query fetchPlaceDetail:^(NSDictionary *placeDictionary, NSError *error) {
        if (error) {
            block(nil, nil, error);
        } else {
            NSString *latitude = placeDictionary[@"geometry"][@"location"][@"lat"];
            NSString *longitude = placeDictionary[@"geometry"][@"location"][@"lng"];
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
            
            [[self geocoder] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
                if (error) {
                    block(nil, nil, error);
                } else {
                    CLPlacemark *placemark = [placemarks onlyObject];
                    block(placemark, self.name, error);
                }
            }];
        }
    }];
}

- (void)resolveGecodePlaceToPlacemark:(SPGooglePlacesPlacemarkResultBlock)block {
    [[self geocoder] geocodeAddressString:self.name completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            block(nil, nil, error);
        } else {
            CLPlacemark *placemark = [placemarks onlyObject];
            block(placemark, self.name, error);
        }
    }];
}

- (void)resolveToPlacemark:(SPGooglePlacesPlacemarkResultBlock)block {
    if (self.type == SPPlaceTypeGeocode) {
        // Geocode places already have their address stored in the 'name' field.
        [self resolveGecodePlaceToPlacemark:block];
    } else {
        [self resolveEstablishmentPlaceToPlacemark:block];
    }
}


@end
