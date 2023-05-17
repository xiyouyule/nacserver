// Tool to extract IOKit data from a running machine and save it to a plist
//
// Usage: ./extractor <plist file>

#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <stdio.h>
#include <DiskArbitration/DiskArbitration.h>
#include <sys/mount.h>

NSDictionary* extract_iokit_data() {
    io_service_t platform_expert_service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                        IOServiceMatching("IOPlatformExpertDevice"));
    if (!platform_expert_service) {
        printf("Failed to get service\n");
        return nil;
    }
    
    NSString* data = (__bridge_transfer NSString*)IORegistryEntryCreateCFProperty(platform_expert_service, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    // Get IOPlatformSerialNumber
    NSString* serial = (__bridge_transfer NSString*)IORegistryEntryCreateCFProperty(platform_expert_service, CFSTR("IOPlatformSerialNumber"), kCFAllocatorDefault, 0);
    if (!data) {
        printf("Failed to get data\n");
        return nil;
    }
    
    // Get from path IODeviceTree:/
    io_service_t device_tree_service = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/");

    if (!device_tree_service) {
        printf("Failed to get service\n");
        return nil;
    }

    // Get board-id
    NSData* board_id = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(device_tree_service, CFSTR("board-id"), kCFAllocatorDefault, 0);
    // Get product-name
    NSData* product_name = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(device_tree_service, CFSTR("product-name"), kCFAllocatorDefault, 0);
    
    // Get path IOPower:/
    io_service_t power_service = IORegistryEntryFromPath(kIOMasterPortDefault, "IOPower:/");

    // Get Gq3489ugfi
    NSData* g_data = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(power_service, CFSTR("Gq3489ugfi"), kCFAllocatorDefault, 0);
    // Get Fyp98tpgj
    NSData* f_data = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(power_service, CFSTR("Fyp98tpgj"), kCFAllocatorDefault, 0);
    // get kbjfrfpoJU
    NSData* k_data = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(power_service, CFSTR("kbjfrfpoJU"), kCFAllocatorDefault, 0);
    //printf("Hello\n");
    //NSLog(@"HI %@", data);

    // Get class IOEthernetInterface
    CFMutableDictionaryRef ethernet_service = IOServiceMatching("IOEthernetInterface");
    // Add key IOPropertyMatch containing dictionary with key IOPrimaryInterface = 1
    CFMutableDictionaryRef property_match = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(property_match, CFSTR("IOPrimaryInterface"), kCFBooleanTrue);
    CFDictionaryAddValue(ethernet_service, CFSTR("IOPropertyMatch"), property_match);
    // Get ethernet services iter
    io_iterator_t ethernet_services_iter;
    IOServiceGetMatchingServices(kIOMasterPortDefault, ethernet_service, &ethernet_services_iter);
    // Get ethernet service
    io_service_t ethernet_service_ = IOIteratorNext(ethernet_services_iter);
    // Get the parent of the ethernet service
    io_service_t ethernet_service_parent;
    IORegistryEntryGetParentEntry(ethernet_service_, kIOServicePlane, &ethernet_service_parent);
    // Get the mac address
    NSData* mac_address = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(ethernet_service_parent, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);

    // Use statfs to get the BSD name of the root disk
    struct statfs statfs_info;
    statfs("/", &statfs_info);
    // Get the BSD name
    NSString* root_disk = [NSString stringWithUTF8String:statfs_info.f_mntfromname];
    // Print the BSD name
    //printf("%s\n", [root_disk UTF8String]);
    NSLog(@"%@", root_disk);
    // Use DiskArbitration to get the UUID of the root disk
    DASessionRef session = DASessionCreate(kCFAllocatorDefault);
    DADiskRef disk = DADiskCreateFromBSDName(kCFAllocatorDefault, session, (const char*)&statfs_info.f_mntfromname);
    CFDictionaryRef disk_info = DADiskCopyDescription(disk);
    // Get the UUID
    CFUUIDRef cf_disk_uuid = CFDictionaryGetValue(disk_info, kDADiskDescriptionVolumeUUIDKey);
    // Convert the UUID to a string
    NSString* disk_uuid = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, cf_disk_uuid);
    // Print the UUID
    //printf("%s\n", [disk_uuid UTF8String]);
    NSLog(@"uuid: %@", disk_uuid);

    // Read 4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:ROM from IODeviceTree:/options
    io_service_t options_service = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/options");
    NSData* rom = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(options_service, CFSTR("4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:ROM"), kCFAllocatorDefault, 0);
    // Read 4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:MLB
    NSData* mlb = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(options_service, CFSTR("4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:MLB"), kCFAllocatorDefault, 0);
    // Print the ROM
    NSLog(@"rom: %@", rom);
    // Print the MLB
    NSLog(@"mlb: %@", mlb);
    //NSData* mac_address = (__bridge_transfer NSData*)IORegistryEntryCreateCFProperty(ethernet_service_, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);

    // Print IOMacAddress, UTF8 decoded
    //printf("%s\n", (char*)[mac_address bytes]);

    return @{
        @"board-id": board_id,
        @"product-name": product_name,
        @"IOPlatformUUID": data,
        @"IOPlatformSerialNumber": serial,
        @"Gq3489ugfi": g_data,
        @"Fyp98tpgj": f_data,
        @"kbjfrfpoJU": k_data,
        @"IOMACAddress": mac_address,
        @"4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:ROM": rom,
        @"4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:MLB": mlb,
        @"root_disk_uuid": disk_uuid,
    };

}

int main() {
    NSDictionary* data = extract_iokit_data();
    NSLog(@"%@", data);
    // Write the data to a plist
    [data writeToFile:@"data.plist" atomically:YES];
    printf("Wrote data to data.plist\n");
}