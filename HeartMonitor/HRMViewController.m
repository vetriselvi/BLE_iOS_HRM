//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Steven F. Daniel on 30/11/13.
//  Copyright (c) 2013 GENIESOFT STUDIOS. All rights reserved.
//

#import "HRMViewController.h"
#import "Constants.h"
#import "Math.h"

@interface HRMViewController () {
CBUUID *HR_Measurement_Characteristic_UUID;
uint16_t bpmOld ;
    CBUUID *HR_DeviceName_Characteristic_UUID;
}
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;

@end

@implementation HRMViewController
@synthesize bluetoothManager;
int flag =0;
uint16_t bpm = 0;
uint16_t bpm2 = 0;
//bpmOld = 0;
//static NSString * const hrsServiceUUIDString = @"0000180D-0000-1000-8000-00805F9B34FB";
////static NSString * const POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID = @"00002A37-0000-1000-8000-00805F9B34FB";
//static NSString * const hrsSensorLocationCharacteristicUUIDString = @"00002A38-0000-1000-8000-00805F9B34FB";
//CBUUID *HR_Measurement_Characteristic_UUID;// [CBUUID UUIDWithString:POLARH7_HRM_NOTIFICATIONS_SERVICE_UUID];

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
//        HR_Service_UUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
//        NSLog(@"HR_Service_UUID is Vetri: check 2: %@",HR_Service_UUID);
        HR_Measurement_Characteristic_UUID = [CBUUID UUIDWithString:hrsHeartRateCharacteristicUUIDString];
        HR_DeviceName_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorDeviceNameUUIDString];
        //HR_Location_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorLocationCharacteristicUUIDString];
        //Battery_Service_UUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        //Battery_Level_Characteristic_UUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self scan]; //change
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.centralManager stopScan]; //change
    
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
        //[central scanForPeripheralsWithServices:POLARH7_HRM_HEART_RATE_SERVICE_UUID options:nil];
        [self scan]; //change
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
    
   //[self scan];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([peripheral state] == CBPeripheralStateDisconnected) {
        NSLog(@"Peripheral is disconnected");
    }
}



/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan
{
    
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
   
    
    NSLog(@"Scanning started");
    //[self.centralManager didDiscoverPeripheral];
    
}




// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"The local name is %@",localName);
    
	if (![localName isEqual:@""]) {
        [self scan];
        if ([localName isEqual:@"VayuHRM_And"])
        {
		// We found the Heart Rate Monitor
		[self.centralManager stopScan]; //change
        NSLog(@"Stopped scan");
		self.polarH7HRMPeripheral = peripheral;
		peripheral.delegate = self;
		[self.centralManager connectPeripheral:peripheral options:nil];
        }
        [self scan];
        if ([localName isEqual:@"VayuHRM_IoS"])
        {
            // We found the Heart Rate Monitor
            [self.centralManager stopScan]; //change
            NSLog(@"Stopped scan");
            self.polarH7HRMPeripheral = peripheral;
            peripheral.delegate = self;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
        [self scan];
        if ([localName isEqual:@"VayuHRM_Win"])
        {
            // We found the Heart Rate Monitor
            [self.centralManager stopScan]; //change
            NSLog(@"Stopped scan");
            self.polarH7HRMPeripheral = peripheral;
            peripheral.delegate = self;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
	}
    
    
    
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central  :(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
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






// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	// Updated value for heart rate measurement received
    [self scan];
	if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID] && [peripheral.name isEqual:@"VayuHRM_And"]) { // D1–2 device
		// Get the Heart Rate Monitor BPM
		//[self getHeartBPMData:characteristic error:error];
        // Get the Heart Rate Monitor BPM
        [characteristic.UUID isEqual:HR_DeviceName_Characteristic_UUID];
        NSLog(@"Device name %@",HR_DeviceName_Characteristic_UUID);
        NSData *data = [characteristic value];      // 1
        NSUInteger dataLength = data.length;
//        NSDictionary *connectionInterval = [characteristic.properties];
        NSLog(@"DataName of the charateristic %@",data);
        NSLog(@"DataLength of the characteristic %lu",(unsigned long)dataLength);
        
        const uint8_t *reportData = [data bytes];
      //  int reportDataNew = [data bytes];
//        uint16_t bpm = 0;
//        uint16_t bpm2 = 0;
//        int bpm = 0;
//        uint16_t bpm2 = 0;
        //uint16_t bpmOld ;
        
        
            NSLog(@"reportData[0] %hhu", reportData[0]);
            NSLog(@"reportData[1] %hhu", reportData[1]);
            NSLog(@"reportData[2] %hhu", reportData[2]);
            NSLog(@"reportData[3] %hhu", reportData[3]);
            NSLog(@"reportData[4] %hhu", reportData[4]);
            NSLog(@"reportData[5] %hhu", reportData[5]);
            NSLog(@"reportData[6] %hhu", reportData[6]);
            NSLog(@"reportData[7] %hhu", reportData[7]);
            NSLog(@"reportData[8] %hhu", reportData[8]);
            NSLog(@"reportData[9] %hhu", reportData[9]);
            NSLog(@"reportData[10] %hhu", reportData[10]);
            NSLog(@"reportData[11] %hhu", reportData[11]);
            NSLog(@"reportData[12] %hhu", reportData[12]);
            NSLog(@"reportData[13] %hhu", reportData[13]);
            NSLog(@"reportData[14] %hhu", reportData[14]);
            NSLog(@"reportData[15] %hhu", reportData[15]);
            NSLog(@"reportData[16] %hhu", reportData[16]);
            NSLog(@"reportData[17] %hhu", reportData[17]);
            NSLog(@"reportData[18] %hhu", reportData[18]);
            //NSLog(@"reportData[19] %hhu", reportData[19]);
          if(flag==0){


        //if ((reportData[0] & 0x01) == 0) {          // 2
            // Retrieve the BPM value for the Heart Rate Monitor
            //bpmOld = bpm;
            bpm = reportData[19];
           
            NSLog(@"reportData[19] %hu", bpm);

           
            
            //NSLog(@"BPM :  ---  %i --- ",bpm);
        //}
        
        
//        else {
//            //bpmOld = bpm;
//            bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[19]));  // 3 (
//            //NSLog(@"BPM :  ---  %i --- ",bpm);
//            NSLog(@"reportData[19] %hu", bpm);
//
//
//        }
            flag++;
        }
    
        
        else if(flag==1){
           // if ((reportData[0] & 0x01) == 0) {          // 2
                // Retrieve the BPM value for the Heart Rate Monitor
                //bpmOld = bpm;
                bpm2 = reportData[19];
                
                
                
                
               // NSLog(@"BPM2 :  ---  %i --- ",bpm2);
                NSLog(@"reportData[19] %hu", bpm2);

//            }
            
//            
//            else {
//                //bpmOld = bpm;
//                bpm2 = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));  // 3 (*(uint16_t *)
//               // NSLog(@"BPM2 :  ---  %i --- ",bpm2);
//                NSLog(@"reportData[19] %hu", bpm2);
//
//
//            }
            flag=0;
        }
        
        
        if (abs((bpm)-abs(bpm2)) != 1 ) {
            NSLog(@"Skips data!!!!!!!!!!!!!!" );
        }
    
        
        
        //uint16_t diff = bpmOld -bpm;
       // NSLog(@"Difference between two consecutive bpms is: %i",abs(bpmOld-bpm));
        
        //[self differenceBPM:bpm];
        
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
    [self scan];
    if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID] && [peripheral.name isEqual:@"VayuHRM_IoS"]) { // 2
        NSLog(@"iOSSSSSSSSSSS");
    }
    [self scan];
    if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID] && [peripheral.name isEqual:@"VayuHRM_Win"]) { // 3
         NSLog(@"Winnnnnnnnnnnnnnn");
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
        NSLog(@"BPM is %hu", bpm);
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

-(void) onConnectionStateChanged {
    NSLog(@"Connection State changed!!!!!!!!");
}


-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error) {
        //Type-Casting NSArray to CBService doesn't work!
        //CBService *hrService = peripheral.services;
        for (CBService *hrService in peripheral.services) {
            //Remember - Get UUID by implementing UUIDWithString, otherwise it will fetch the raw string
            if ([hrService.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]])
            {
                NSLog(@"HR service found");
                NSLog(@"Vetri: check1");
                
                [peripheral discoverCharacteristics:nil forService:hrService];
            }
            else{
                NSLog(@"Not in the If Loop");
            }
            
        }
    } else {
        NSLog(@"Error occurred while discovering service: %@",[error localizedDescription]);
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID]) {
                    NSLog(@"HR Measurement characteritsic found");

                    [peripheral setNotifyValue:YES forCharacteristic:characteristic ];

                    }
                    
           
            }
        }

            
        }

else {
        NSLog(@"Error occurred while discovering characteristic: %@",[error localizedDescription]);
    }
}
//}
//
//- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    
//    
//}





@end