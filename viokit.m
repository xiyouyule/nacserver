#include <CoreFoundation/CoreFoundation.h>
//#include <Foundation/Foundation.h>
#include <IOKit/IOTypes.h>
#include <stdio.h>
// #include <Foundation/Foundation.h>
#include <Foundation/NSData.h>
#include <Foundation/NSPropertyList.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>

// Helpers
NSDictionary* read_data_plist() {
  // Read data.plist from the current directory
  NSString* path = @"data.plist";
  NSData* data = [NSData dataWithContentsOfFile:path];
  if (!data) {
    printf("Failed to read data.plist\n");
    return nil;
  }
  NSError* error;
  NSDictionary* plist = [NSPropertyListSerialization
      propertyListWithData:data
                   options:NSPropertyListImmutable
                    format:NULL
                     error:&error];
  if (error) {
    printf("Failed to parse data.plist\n");
    return nil;
  }
  return plist;
}

#define CFSTR_CMP(str1, str2) CFStringCompare(str1, str2, 0) == 0

CFDataRef data_from_cfstr(CFStringRef string) {
  CFIndex length = CFStringGetLength(string);
  CFIndex maxSize =
      CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8);
  char *buffer = (char *)malloc(maxSize);
  if (CFStringGetCString(string, buffer, maxSize, kCFStringEncodingUTF8)) {
    return CFDataCreate(NULL, (const UInt8 *)buffer, maxSize);
  } else {
    return NULL;
  }
}

// Stubs
#define G_DATA_NAME "Gq3489ugfi"
#define F_DATA_NAME "Fyp98tpgj"
#define k_DATA_NAME "kbjfrfpoJU"
#define o_DATA_NAME "oycqAZloTNDm"
#define a_DATA_NAME "abKPld1EcMni"

mach_port_t kIOMasterPortDefault = 90;

io_registry_entry_t IORegistryEntryFromPath(mach_port_t masterPort,
                                            char *path) {
  printf("IORegistryEntryFromPath called with port %d path: %s\n", masterPort,
         path);
  return 91;
}

NSDictionary* DATA_PLIST = nil;

CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry,
                                          CFStringRef key,
                                          CFAllocatorRef allocator,
                                          IOOptionBits options) {
  // Convert the CFStringRef to a C string
  char key_c[100];
  CFStringGetCString(key, key_c, 100, kCFStringEncodingUTF8);
  printf("IORegistryEntryCreateCFProperty called with entry: %d key: %s\n",
         entry, key_c);

  // Check if the key is in data.plist
  if (DATA_PLIST == nil) {
    DATA_PLIST = read_data_plist();
    if (!DATA_PLIST) {
      printf("Failed to read data.plist\n");
      return NULL;
    }
  }
  NSDictionary* data_plist = DATA_PLIST;
  // Convert the CFStringRef to a NSString
  NSString* key_ns = (__bridge_transfer NSString*)key;
  // Check if the key is in the dictionary
  if ([data_plist objectForKey:key_ns]) {
    // Get the value
    id value = [data_plist objectForKey:key_ns];
    // Check if it is a string
    if ([value isKindOfClass:[NSString class]]) {
      // Convert the NSString to a CFStringRef
      CFStringRef value_cf = (__bridge_retained CFStringRef)value;
      // Create a CFDataRef from the CFStringRef
      CFDataRef value_data = data_from_cfstr(value_cf);
      // Release the CFStringRef
      CFRelease(value_cf);
      // Return the CFDataRef
      return value_data;
    } else if ([value isKindOfClass:[NSNumber class]]) {
      // Convert the NSNumber to a CFNumberRef
      CFNumberRef value_cf = (__bridge_retained CFNumberRef)value;
      // Create a CFDataRef from the CFNumberRef
      CFDataRef value_data = CFDataCreate(NULL, (const UInt8 *)&value_cf,
                                          sizeof(value_cf));
      // Release the CFNumberRef
      CFRelease(value_cf);
      // Return the CFDataRef
      return value_data;
    } else if ([value isKindOfClass:[NSData class]]) {
      // Convert the NSData to a CFDataRef
      CFDataRef value_cf = (__bridge_retained CFDataRef)value;
      // Return the CFDataRef
      return value_cf;
    } else {
      // Return NULL
      return NULL;
    }
  } else {
    // Return NULL
    return NULL;
  }

  // Check the key
//   if (CFSTR_CMP(key, CFSTR("board-id"))) {
//     return data_from_cfstr(CFSTR(FAKE_BOARD_ID));
//   } else if (CFSTR_CMP(key, CFSTR("product-name"))) {
//     return data_from_cfstr(CFSTR(FAKE_MODEL));
//   } else if (CFSTR_CMP(key, CFSTR("IOPlatformSerialNumber"))) {
//     return CFSTR(FAKE_SERIAL);
//   } else if (CFSTR_CMP(key, CFSTR("IOPlatformUUID"))) {
//     return CFSTR(FAKE_HW_UUID);
//   } else if (CFSTR_CMP(key, CFSTR(G_DATA_NAME))) {
//     // Create CFDataRef from FAKE_G_DATA
//     return CFDataCreate(NULL, (const UInt8 *)&FAKE_G_DATA, sizeof(FAKE_G_DATA));
//   } else if (CFSTR_CMP(key, CFSTR(F_DATA_NAME))) {
//     // Create CFDataRef from FAKE_F_DATA
//     return CFDataCreate(NULL, (const UInt8 *)&FAKE_F_DATA, sizeof(FAKE_F_DATA));
//   } else if (CFSTR_CMP(key, CFSTR(k_DATA_NAME))) {
//     // Create CFDataRef from FAKE_k_DATA
//     return CFDataCreate(NULL, (const UInt8 *)&FAKE_k_DATA, sizeof(FAKE_k_DATA));
//   } else if (CFSTR_CMP(key, CFSTR("IOMACAddress"))) {
//     // Create CFDataRef from FAKE_ROM, which is a uint64_t, but we only want the
//     // 6 least significant bytes
//     return CFDataCreate(NULL, (const UInt8 *)&FAKE_ROM + 2, 6);
//   }
//   /*else if (CFSTR_CMP(key, CFSTR(o_DATA_NAME))) {
//    // Create CFDataRef from FAKE_o_DATA
//    return CFDataCreate(NULL, (const UInt8 *)&FAKE_o_DATA, sizeof(FAKE_o_DATA));
//  } else if (CFSTR_CMP(key, CFSTR(a_DATA_NAME))) {
//    // Create CFDataRef from FAKE_a_DATA
//    return CFDataCreate(NULL, (const UInt8 *)&FAKE_a_DATA, sizeof(FAKE_a_DATA));
//  }*/
//   else {
//     // Return NULL
//     return NULL;
//   }
}

CFMutableDictionaryRef IOServiceMatching(const char *name) {
  // printf("IOServiceMatching called with %s\n", name);
  //  return 0;
  //   Turn name into CFString
  CFStringRef name_cf =
      CFStringCreateWithCString(NULL, name, kCFStringEncodingUTF8);
  // Create a CFMutableDictionaryRef
  CFMutableDictionaryRef matching =
      CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                &kCFTypeDictionaryValueCallBacks);
  // Add the name to the dictionary
  CFDictionaryAddValue(matching, CFSTR("IOProviderClass"), name_cf);
  // Return the dictionary
  return matching;
}

io_service_t IOServiceGetMatchingService(mach_port_t masterPort,
                                         CFDictionaryRef matching) {
  // Print the CFDictionary
  // CFShow(matching);
  // printf("IOServiceGetMatchingService called with port: %d matching: \n",
  //      masterPort);
  // CFShow(matching);

  // Get the IOProviderClass
  CFStringRef provider_class =
      CFDictionaryGetValue(matching, CFSTR("IOProviderClass"));

  // Check if it is 'IOPlatformExpertDevice'
  if (CFSTR_CMP(provider_class, CFSTR("IOPlatformExpertDevice"))) {
    return 92;
  }
  return 0;
}

bool ITER_93_SHOULD_RETURN_MAC = false;
kern_return_t IOServiceGetMatchingServices(mach_port_t masterPort,
                                           CFDictionaryRef matching,
                                           io_iterator_t *existing) {
  printf("IOServiceGetMatchingServices called with port: %d matching: \n",
         masterPort);
  CFShow(matching);
  if (CFSTR_CMP(CFDictionaryGetValue(matching, CFSTR("IOProviderClass")),
                CFSTR("IOEthernetInterface"))) {
    // printf("IOServiceGetMatchingServices returning 0\n");
    *existing = 93;
    ITER_93_SHOULD_RETURN_MAC = true;
    return 0;
  }
  return -1;
}

io_object_t IOIteratorNext(io_iterator_t iterator) {
  printf("IOIteratorNext\n");
  if (iterator == 93 && ITER_93_SHOULD_RETURN_MAC) {
    ITER_93_SHOULD_RETURN_MAC = false;
    return 94;
  }
  return 0;
}

void IOObjectRelease(io_object_t object) { printf("IOObjectRelease\n"); }

kern_return_t IORegistryEntryGetParentEntry(io_registry_entry_t entry,
                                            const io_name_t plane,
                                            io_registry_entry_t *parent) {
  printf("IORegistryEntryGetParentEntry called wiht entry: %d and plane: %s "
         "and parent %p\n",
         entry, plane, parent);
  // Set parent to entry + 100
  *parent = entry + 100;
  // printf("IORegistryEntryGetParentEntry returning 0\n");
  return 0;
}

// IOIteratorNext
// IOObjectRelease
// IORegistryEntryCreateCFProperty
// IORegistryEntryFromPath
// IORegistryEntryGetParentEntry
// IOServiceGetMatchingService
// IOServiceGetMatchingServices
// IOServiceMatching

// ALSO STUB DA IN SAME FILE?!