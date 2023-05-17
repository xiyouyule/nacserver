#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOTypes.h>
#include <stdio.h>

// Fake data
#define FAKE_MODEL "MacPro5,1"
#define FAKE_BOARD_ID "Mac-F221BEC8"
#define FAKE_SERIAL "CK1350NCEUH"
#define FAKE_HW_UUID "ABB178CD-25C5-5AFB-A749-B432FD683AE1"
//#define FAKE_SYS_UUID "ADEAE"
#define FAKE_ROM 0xb48b1988b880
#define FAKE_BOARD_SERIAL "CK1350351BH8U"

//#define FAKE_G_DATA [0x1663a52f1d827299e41d56d74223ecca60]
//const uint8_t[] FAKE_G_DATA = uint8_t[0x16, 0x63, 0xa5, 0x2f, 0x1d, 0x82, 0x72, 0x99, 0xe4, 0x1d, 0x56, 0xd7, 0x42, 0x23, 0xec, 0xca, 0x60]
const uint8_t FAKE_G_DATA[] = {0x16, 0x63, 0xa5, 0x2f, 0x1d, 0x82, 0x72, 0x99, 0xe4, 0x1d, 0x56, 0xd7, 0x42, 0x23, 0xec, 0xca, 0x60};
//const uint8_t[] fake_g_data = FAKE_G_DATA;
//#define FAKE_F_DATA [0x95987adcec1a31eccd63a9ba21e182fadb]
//#define FAKE_F_DATA [0x95, 0x98, 0x7a, 0xdc, 0xec, 0x1a, 0x31, 0xec, 0xcd, 0x63, 0xa9, 0xba, 0x21, 0xe1, 0x82, 0xfa, 0xdb]
const uint8_t FAKE_F_DATA[] = {0x95, 0x98, 0x7a, 0xdc, 0xec, 0x1a, 0x31, 0xec, 0xcd, 0x63, 0xa9, 0xba, 0x21, 0xe1, 0x82, 0xfa, 0xdb};
//#define FAKE_k_DATA [0x6e7092c5131ea9378f57e9d109ed010112]
//#define FAKE_k_DATA [0x6e, 0x70, 0x92, 0xc5, 0x13, 0x1e, 0xa9, 0x37, 0x8f, 0x57, 0xe9, 0xd1, 0x09, 0xed, 0x01, 0x01, 0x12]
const uint8_t FAKE_k_DATA[] = {0x6e, 0x70, 0x92, 0xc5, 0x13, 0x1e, 0xa9, 0x37, 0x8f, 0x57, 0xe9, 0xd1, 0x09, 0xed, 0x01, 0x01, 0x12};
//#define FAKE_o_DATA [0x71dbaec99c49cef0a5addcb0e2be0b2f2d]
//#define FAKE_o_DATA [0x71, 0xdb, 0xae, 0xc9, 0x9c, 0x49, 0xce, 0xf0, 0xa5, 0xad, 0xdc, 0xb0, 0xe2, 0xbe, 0x0b, 0x2f, 0x2d]
const uint8_t FAKE_o_DATA[] = {0x71, 0xdb, 0xae, 0xc9, 0x9c, 0x49, 0xce, 0xf0, 0xa5, 0xad, 0xdc, 0xb0, 0xe2, 0xbe, 0x0b, 0x2f, 0x2d};
//#define FAKE_a_DATA [0x9d94ed553d6d55a09074f667aa6b6cd155]
//#define FAKE_a_DATA [0x9d, 0x94, 0xed, 0x55, 0x3d, 0x6d, 0x55, 0xa0, 0x90, 0x74, 0xf6, 0x67, 0xaa, 0x6b, 0x6c, 0xd1, 0x55]
const uint8_t FAKE_a_DATA[] = {0x9d, 0x94, 0xed, 0x55, 0x3d, 0x6d, 0x55, 0xa0, 0x90, 0x74, 0xf6, 0x67, 0xaa, 0x6b, 0x6c, 0xd1, 0x55};

// Helpers
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

CFTypeRef IORegistryEntryCreateCFProperty(io_registry_entry_t entry,
                                          CFStringRef key,
                                          CFAllocatorRef allocator,
                                          IOOptionBits options) {
  // Convert the CFStringRef to a C string
  char key_c[100];
  CFStringGetCString(key, key_c, 100, kCFStringEncodingUTF8);
  printf("IORegistryEntryCreateCFProperty called with entry: %d key: %s\n",
         entry, key_c);
  // Check the key
  if (CFSTR_CMP(key, CFSTR("board-id"))) {
    return data_from_cfstr(CFSTR(FAKE_BOARD_ID));
  } else if (CFSTR_CMP(key, CFSTR("product-name"))) {
    return data_from_cfstr(CFSTR(FAKE_MODEL));
  } else if (CFSTR_CMP(key, CFSTR("IOPlatformSerialNumber"))) {
    return CFSTR(FAKE_SERIAL);
  } else if (CFSTR_CMP(key, CFSTR("IOPlatformUUID"))) {
    return CFSTR(FAKE_HW_UUID);
  } else if (CFSTR_CMP(key, CFSTR(G_DATA_NAME))) {
    // Create CFDataRef from FAKE_G_DATA
    return CFDataCreate(NULL, (const UInt8 *)&FAKE_G_DATA, sizeof(FAKE_G_DATA));
  } else if (CFSTR_CMP(key, CFSTR(F_DATA_NAME))) {
    // Create CFDataRef from FAKE_F_DATA
    return CFDataCreate(NULL, (const UInt8 *)&FAKE_F_DATA, sizeof(FAKE_F_DATA));
  } else if (CFSTR_CMP(key, CFSTR(k_DATA_NAME))) {
    // Create CFDataRef from FAKE_k_DATA
    return CFDataCreate(NULL, (const UInt8 *)&FAKE_k_DATA, sizeof(FAKE_k_DATA));
  } /*else if (CFSTR_CMP(key, CFSTR(o_DATA_NAME))) {
    // Create CFDataRef from FAKE_o_DATA
    return CFDataCreate(NULL, (const UInt8 *)&FAKE_o_DATA, sizeof(FAKE_o_DATA));
  } else if (CFSTR_CMP(key, CFSTR(a_DATA_NAME))) {
    // Create CFDataRef from FAKE_a_DATA
    return CFDataCreate(NULL, (const UInt8 *)&FAKE_a_DATA, sizeof(FAKE_a_DATA));
  }*/ 
  else {
    // Return NULL
    return NULL;
  }
}

CFMutableDictionaryRef IOServiceMatching(const char *name) {
  //printf("IOServiceMatching called with %s\n", name);
  // return 0;
  //  Turn name into CFString
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
  //printf("IOServiceGetMatchingService called with port: %d matching: \n",
  //       masterPort);
  //CFShow(matching);

  // Get the IOProviderClass
  CFStringRef provider_class =
      CFDictionaryGetValue(matching, CFSTR("IOProviderClass"));
  
  // Check if it is 'IOPlatformExpertDevice'
  if (CFSTR_CMP(provider_class, CFSTR("IOPlatformExpertDevice"))) {
    return 92;
  }
  return 0;
}

io_object_t IOIteratorNext(io_iterator_t iterator) {
  printf("IOIteratorNext\n");
  return 0;
}

void IOObjectRelease(io_object_t object) { printf("IOObjectRelease\n"); }

kern_return_t IORegistryEntryGetParentEntry(io_registry_entry_t entry,
                                            const io_name_t plane,
                                            io_registry_entry_t *parent) {
  printf("IORegistryEntryGetParentEntry\n");
  return 0;
}

kern_return_t IOServiceGetMatchingServices(mach_port_t masterPort,
                                           CFDictionaryRef matching,
                                           io_iterator_t *existing) {
  printf("IOServiceGetMatchingServices\n");
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