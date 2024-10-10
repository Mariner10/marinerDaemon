#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
+ (instancetype)sharedInstance;
- (void)startUpdatingLocation;
@end

@implementation LocationManager

+ (instancetype)sharedInstance {
    static LocationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupLocationManager];
    }
    return self;
}

- (void)setupLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // Less battery intensive
    self.locationManager.distanceFilter = 100.0; // Update every 100 meters
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    // Important: Set this for background updates
    if (@available(iOS 9.0, *)) {
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    if (@available(iOS 11.0, *)) {
        self.locationManager.showsBackgroundLocationIndicator = YES;
    }
}

- (void)startUpdatingLocation {
    [self logMessage:@"Requesting location authorization"];
    [self.locationManager requestAlwaysAuthorization];
    
    // Use significant location changes instead of standard updates
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    [self logMessage:[NSString stringWithFormat:@"Location updated: %@", location]];
    
    if (!self.lastLocation || [self.lastLocation distanceFromLocation:location] >= 100.0) {
        [self sendLocationToAPI:location];
        self.lastLocation = location;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self logMessage:[NSString stringWithFormat:@"Location Error: %@", error.localizedDescription]];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self logMessage:[NSString stringWithFormat:@"Authorization status changed: %d", status]];
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)sendLocationToAPI:(CLLocation *)location {
    NSString *urlString = [NSString stringWithFormat:@"https://carterbeaudoin2.ddns.net/location?lat=%f&lon=%f&alt=%f&speed=%f",
                           location.coordinate.latitude,
                           location.coordinate.longitude,
                           location.altitude,
                           location.speed];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self logMessage:[NSString stringWithFormat:@"Error sending location: %@", error]];
        } else {
            [self logMessage:@"Location sent successfully"];
        }
    }];
    [task resume];
}

- (void)logMessage:(NSString *)message {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *logMessage = [NSString stringWithFormat:@"%@ - %@\n", timestamp, message];
    
    NSLog(@"LocationPush: %@", logMessage);
    
    NSString *logFilePath = @"/var/log/locationpush.log";
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    if (!fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    }
    
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        NSLog(@"LocationPush Error: Unable to open or create log file");
    }
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        [[LocationManager sharedInstance] logMessage:@"LocationPush daemon started"];
        [[LocationManager sharedInstance] startUpdatingLocation];
        
        // Keep the run loop alive
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
    return 0;
}