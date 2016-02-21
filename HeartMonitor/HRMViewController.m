//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Steven F. Daniel on 30/11/13.
//  Copyright (c) 2013 GENIESOFT STUDIOS. All rights reserved.
//

#import "HRMViewController.h"

@interface HRMViewController ()
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;

@end

@implementation HRMViewController
@synthesize bluetoothManager;

static NSString * const hrsServiceUUIDString = @"0000180D-0000-1000-8000-00805F9B34FB";
//static NSString * const POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID = @"00002A37-0000-1000-8000-00805F9B34FB";
static NSString * const hrsSensorLocationCharacteristicUUIDString = @"00002A38-0000-1000-8000-00805F9B34FB";
CBUUID *HR_Measurement_Characteristic_UUID;// [CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID];

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	self.polarH7DeviceData = nil;
	[self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	[self.heartImage setImage:[UIImage imageNamed:@"HeartImage"]];
	
	// Clear out textView
	[self.deviceInfo setText:@""];
	[self.deviceInfo setTextColor:[UIColor blueColor]];
	[self.deviceInfo setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	[self.deviceInfo setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:25]];
	[self.deviceInfo setUserInteractionEnabled:NO];
	
	// Create our Heart Rate BPM Label
	self.heartRateBPM = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 75, 50)];
	[self.heartRateBPM setTextColor:[UIColor whiteColor]];
	[self.heartRateBPM setText:[NSString stringWithFormat:@"%i", 0]];
	[self.heartRateBPM setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:28]];
	[self.heartImage addSubview:self.heartRateBPM];
	
	// Scan for all available CoreBluetooth LE devices
	NSArray *services = @[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]; //, [CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID], [CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID], [CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID]
	CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
	[centralManager scanForPeripheralsWithServices:services options:nil];
	self.centralManager = centralManager;
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	// Determine the state of the peripheral
	if ([central state] == CBCentralManagerStatePoweredOff) {
		NSLog(@"CoreBluetooth BLE hardware is powered off");
	}
	else if ([central state] == CBCentralManagerStatePoweredOn) {
		NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
	}
	else if ([central state] == CBCentralManagerStateUnauthorized) {
		NSLog(@"CoreBluetooth BLE state is unauthorized");
	}
	else if ([central state] == CBCentralManagerStateUnknown) {
		NSLog(@"CoreBluetooth BLE state is unknown");
	}
	else if ([central state] == CBCentralManagerStateUnsupported) {
		NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
	}
    [self scan];
}
//- (void)centralManagerDidUpdateState:(CBCentralManager *)central
//{
//    if (central.state != CBCentralManagerStatePoweredOn) {
//        // In a real app, you'd deal with all the states correctly
//        return;
//    }
//    
//    // The state must be CBCentralManagerStatePoweredOn...
//    
//    // ... so start scanning
//    [self scan];
//    
//}


/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}


// method called whenever we have successfully connected to the BLE peripheral
//- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
//{
//	[peripheral setDelegate:self];
//    [peripheral discoverServices:nil];
//	self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
//}

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
//{
//	for (CBService *service in peripheral.services) {
//		[peripheral discoverCharacteristics:nil forService:service];
//	}
//}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
//- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
//{
//	NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
//	if (![localName isEqual:@""]) {
//		// We found the Heart Rate Monitor
//		[self.centralManager stopScan];
//		self.polarH7HRMPeripheral = peripheral;
//		peripheral.delegate = self;
//		[self.centralManager connectPeripheral:peripheral options:nil];
//	}
//}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB) - But the Nordic HRM I tested has strength of -70dB, so can't cut off
//    if (RSSI.integerValue < -35) {
//        return;
//    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
 //   [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
   // [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]];
}


// Invoked when you discover the characteristics of a specified service.
//- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
//{
//	if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]])  {  // 1
//		for (CBCharacteristic *aChar in service.characteristics)
//		{
//			// Request heart rate notifications
//			if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID]]) { // 2
//				[self.polarH7HRMPeripheral setNotifyValue:YES forCharacteristic:aChar];
//			}
//			// Request body sensor location
//			else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_UUID]]) { // 3
//				[self.polarH7HRMPeripheral readValueForCharacteristic:aChar];
//			}
////			else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_ENABLE_SERVICE_UUID]]) { // 4
////				// Read the value of the heart rate sensor
////				UInt8 value = 0x01;
////				NSData *data = [NSData dataWithBytes:&value length:sizeof(value)];
////				[peripheral writeValue:data forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
////			}
//		}
//	}
//	// Retrieve Device Information Services for the Manufacturer Name
//	if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]])  { // 5
//        for (CBCharacteristic *aChar in service.characteristics)
//        {
//            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_UUID]]) {
//                [self.polarH7HRMPeripheral readValueForCharacteristic:aChar];
//                NSLog(@"Found a Device Manufacturer Name Characteristic");
//            }
//        }
//	}
//}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	// Updated value for heart rate measurement received
	if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID]]) { // 1
		// Get the Heart Rate Monitor BPM
		[self getHeartBPMData:characteristic error:error];
	}
	// Retrieve the characteristic value for manufacturer name received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_UUID]]) {  // 2
		[self getManufacturerName:characteristic];
    }
	// Retrieve the characteristic value for the body sensor location received
	else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_UUID]]) {  // 3
		[self getBodyLocation:characteristic];
    }
	
	// Add our constructed device information to our UITextView
	self.deviceInfo.text = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.connected, self.bodyData, self.manufacturer];  // 4
}

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
	// Get the Heart Rate Monitor BPM
	NSData *data = [characteristic value];      // 1
	const uint8_t *reportData = [data bytes];
	uint16_t bpm = 0;
	
	if ((reportData[0] & 0x01) == 0) {          // 2
		// Retrieve the BPM value for the Heart Rate Monitor
		bpm = reportData[1];
	}
	else {
		bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));  // 3
	}
	// Display the heart rate value to the UI if no error occurred
	if( (characteristic.value)  || !error ) {   // 4
		self.heartRate = bpm;
		self.heartRateBPM.text = [NSString stringWithFormat:@"%i bpm", bpm];
		self.heartRateBPM.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:28];
		[self doHeartBeat];
		self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
	}
	return;
}

// Instance method to get the manufacturer name of the device
- (void) getManufacturerName:(CBCharacteristic *)characteristic
{
	NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
	self.manufacturer = [NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];
	return;
}

// Instance method to get the body location of the device
- (void) getBodyLocation:(CBCharacteristic *)characteristic
{
	NSData *sensorData = [characteristic value];
	uint8_t *bodyData = (uint8_t *)[sensorData bytes];
	if (bodyData ) {
		uint8_t bodyLocation = bodyData[0];
		self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"];
	}
	else {
		self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
	}
	return;
}

// instance method to stop the device from rotating - only support the Portrait orientation
- (NSUInteger) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
}

// instance method to simulate our pulsating Heart Beat
- (void) doHeartBeat
{
	CALayer *layer = [self heartImage].layer;
	CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	pulseAnimation.toValue = [NSNumber numberWithFloat:1.1];
	pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
	
	pulseAnimation.duration = 60. / self.heartRate / 2.;
	pulseAnimation.repeatCount = 1;
	pulseAnimation.autoreverses = YES;
	pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	[layer addAnimation:pulseAnimation forKey:@"scale"];
	
	self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
}

// handle memory warning errors
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#
-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    peripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:peripheral options:options];
}

#

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        for (CBService *hrService in peripheral.services) {
            if ([hrService.UUID isEqual:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID])
            {
                NSLog(@"HR service found");
                NSLog(@"Vetri: check1");
                
                [peripheral discoverCharacteristics:nil forService:hrService];
            }
//            else if ([hrService.UUID isEqual:Battery_Service_UUID])
//            {
//                NSLog(@"Battery service found");
//                [peripheral discoverCharacteristics:nil forService:hrService];
//            }
            
        }
    } else {
        NSLog(@"Error occurred while discovering service: %@",[error localizedDescription]);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //HR_Measurement_Characteristic_UUID = 2A37;

    if (!error) {
        if ([service.UUID isEqual:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                    NSLog(@"HR Measurement characteritsic found");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic ];
                }
//                else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
//                    NSLog(@"Body Sensor Location characteristic found");
//                    [peripheral readValueForCharacteristic:characteristic];
//                }
            }
        }
//        else if ([service.UUID isEqual:Battery_Service_UUID]) {
//            for (CBCharacteristic *characteristic in service.characteristics)
//            {
//                if ([characteristic.UUID isEqual:Battery_Level_Characteristic_UUID]) {
//                    NSLog(@"Battery Level characteristic found");
//                    [hrPeripheral readValueForCharacteristic:characteristic];
//                }
//            }
//        }
    } else {
        NSLog(@"Error occurred while discovering characteristic: %@",[error localizedDescription]);
    }
}

//-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (!error) {
//            if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
//                int value = [self decodeHRValue:characteristic.value];
//                [self addHRValueToGraph: value];
//                hrValue.text = [NSString stringWithFormat:@"%d", value];
//            }
//            else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID]) {
//                hrLocation.text = [self decodeHRLocation:characteristic.value];
//            }
//            else if ([characteristic.UUID isEqual:Battery_Level_Characteristic_UUID]) {
//                const uint8_t *array = [characteristic.value bytes];
//                uint8_t batteryLevel = array[0];
//                NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
//                [battery setTitle:text forState:UIControlStateDisabled];
//                
//                if (battery.tag == 0)
//                {
//                    // If battery level notifications are available, enable them
//                    if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
//                    {
//                        battery.tag = 1; // mark that we have enabled notifications
//                        
//                        // Enable notification on data characteristic
//                        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
//                    }
//                }
//            }
//        }
//        else {
//            NSLog(@"Error occurred while updating characteristic value: %@",[error localizedDescription]);
//        }
//    });
//}

-(int) decodeHRValue:(NSData *)data
{
    const uint8_t *value = [data bytes];
    int bpmValue = 0;
    if ((value[0] & 0x01) == 0) {
        bpmValue = value[1];
    }
    else {
        bpmValue = CFSwapInt16LittleToHost(*(uint16_t *)(&value[1]));
    }
    return bpmValue;
}

-(NSString *) decodeHRLocation:(NSData *)data
{
    const uint8_t *location = [data bytes];
    NSString *hrmLocation;
    switch (location[0]) {
        case 0:
            hrmLocation = @"Other";
            break;
        case 1:
            hrmLocation = @"Chest";
            break;
        case 2:
            hrmLocation = @"Wrist";
            break;
        case 3:
            hrmLocation = @"Finger";
            break;
        case 4:
            hrmLocation = @"Hand";
            break;
        case 5:
            hrmLocation = @"Ear Lobe";
            break;
        case 6:
            hrmLocation = @"Foot";
            break;
        default:
            hrmLocation = @"Invalid";
            break;
    }
    return hrmLocation;
}

- (void) clearUI
{
//    deviceName.text = @"DEFAULT HRM";
//    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
//    battery.tag = 0;
//    hrLocation.text = @"n/a";
//    hrValue.text = @"-";
//    
//    // Clear and reset the graph
//    [hrValues removeAllObjects];
//    [xValues removeAllObjects];
//    [self resetPlotRange];
//    [self.graph reloadData];
}

@end