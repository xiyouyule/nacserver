#import <dlfcn.h>
#import <stdio.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOCFSerialize.h>
#import <IOKit/IOKitLib.h>

#define APPLE_SERVICES_FRAMEWORK_PATH "IMDAppleServices.stubbed"

// Requests the validation certificate chain from Apple
NSData *request_cert() {
  // Make a request to
  // http://static.ess.apple.com/identity/validation/cert-1.0.plist
  // NSMutableURLRequest *req = [NSMutableURLRequest
  //     requestWithURL:[NSURL
  //                        URLWithString:@"http://static.ess.apple.com/identity/"
  //                                      @"validation/cert-1.0.plist"]];
  // [req setHTTPMethod:@"GET"];

  // NSURLResponse *response = nil;
  // NSError *error = nil;
  /*NSData *data = [NSURLConnection sendSynchronousRequest:req
                                       returningResponse:&response
                                                   error:&error];*/
  // Use the new api for sending requests


  // if (error) {
  //   printf("error: %s\n", [[error description] UTF8String]);
  //   return nil;
  // }

  // NSDictionary *plist =
  //     [NSPropertyListSerialization propertyListWithData:data
  //                                               options:0
  //                                                format:NULL
  //                                                 error:&error];
  // if (error) {
  //   printf("error: %s\n", [[error description] UTF8String]);
  //   return nil;
  // }
  return [NSDictionary dictionaryWithContentsOfURL:[NSURL
                         URLWithString:@"http://static.ess.apple.com/identity/"
                                       @"validation/cert-1.0.plist"]][@"cert"];
  //return plist[@"cert"];
}

NSData *initialize_validation(NSData *request_bytes) {
  // Makes a POST to
  // https://identity.ess.apple.com/WebObjects/TDIdentityService.woa/wa/initializeValidation
  // with a plist containing the request bytes
  NSMutableURLRequest *req = [NSMutableURLRequest
      requestWithURL:[NSURL
                         URLWithString:@"https://identity.ess.apple.com/"
                                       @"WebObjects/TDIdentityService.woa/wa/"
                                       @"initializeValidation"]];
  [req setHTTPMethod:@"POST"];
  // Set the content type to application/x-apple-plist
  [req setValue:@"application/x-apple-plist"
      forHTTPHeaderField:@"Content-Type"];
  [req setHTTPBody:[NSPropertyListSerialization
                       dataWithPropertyList:@{
                         @"session-info-request" : request_bytes
                       }
                                     format:NSPropertyListXMLFormat_v1_0
                                    options:0
                                      error:nil]];

  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:req
                                       returningResponse:&response
                                                   error:&error];
  if (error) {
    printf("error: %s\n", [[error description] UTF8String]);
    return nil;
  }

  NSDictionary *plist =
      [NSPropertyListSerialization propertyListWithData:data
                                                options:0
                                                 format:NULL
                                                  error:&error];
  if (error) {
    printf("error: %s\n", [[error description] UTF8String]);
    return nil;
  }
  // Print the plist
  // printf("plist: %s\n", [[plist description] UTF8String]);
  return plist[@"session-info"];
}

void *load_framework() {
  void *handle = dlopen(APPLE_SERVICES_FRAMEWORK_PATH, RTLD_LAZY);
  if (!handle) {
    printf("dlopen failed: %s\n", dlerror());
    exit(-1);
  }
  return handle;
}

void *calculate_base(void *handle) {
#define REF_SYM "IMDAppleIDClientIdentifier"
#define REF_ADR 0x00000000000d728

  void *real_adr = dlsym(handle, REF_SYM);
  if (!real_adr) {
    printf("dlsym failed: %s\n", dlerror());
    exit(-1);
  }

  return real_adr - REF_ADR;
}

void *HANDLE = NULL;
void *BASE = NULL;

void setup() {
  if (!HANDLE) {
    //printf("loading framework\n");
    NSLog(@"Loading framework...");
    HANDLE = load_framework();
    NSLog(@"Framework loaded!");
    //printf("loaded framework\n");
  }
  if (!BASE) {
    // printf("calculating base\n");
    BASE = calculate_base(HANDLE);
    NSLog(@"Calculated base address: %p", BASE);
  }
}

int NACInit(const void *cert_bytes, int cert_len, void **validation_ctx,
            void **request_bytes, int *request_len) {
#define NACINIT_OFFSET 0xb1db0
  setup();

  //printf("NACInit called\n");
  int (*nac_init)(void *, int, void *, void *, void *) = BASE + NACINIT_OFFSET;
  return nac_init((void *)cert_bytes, cert_len, validation_ctx, request_bytes,
                  request_len);
}

int NACSubmitResponse(void *validation_ctx, void *response_bytes,
                      int response_len) {
#define NACSUBMITRESPONSE_OFFSET 0xb1dd0
  setup();

  //printf("NACSubmitResponse called\n");
  int (*nac_submit_response)(void *, void *, int) =
      BASE + NACSUBMITRESPONSE_OFFSET;
  return nac_submit_response(validation_ctx, response_bytes, response_len);
}

int NACGenerateValidationData(void *validation_ctx, void *unknown_1,
                              void *unknown_2, void **validation_data,
                              int *validation_data_len) {
#define NACGENERATEVALIDATIONDATA_OFFSET 0xb1df0
  setup();

  //printf("NACGenerateValidationData called\n");
  int (*nac_generate_validation_data)(void *, void *, void *, void *, int *) =
      BASE + NACGENERATEVALIDATIONDATA_OFFSET;
  return nac_generate_validation_data(validation_ctx, unknown_1, unknown_2,
                                      validation_data, validation_data_len);
}


int main() {

  // hello();
  //CFTypeRef test = IORegistryEntryCreateCFProperty();
  NSLog(@"Sanity checking NACInit...");
  int ret = NACInit(0, 0, 0, 0, 0);
  if (ret != -44023) {
    NSLog(@"NACInit failed sanity check, returned %d", ret);
    exit(-1);
    //printf("got unexpected result from all-null test: %d\n", ret);
  }

  NSLog(@"Requesting cert...");
  NSData *certData = request_cert();
  NSLog(@"Got cert!");

  NSLog(@"Initializing validation context...");
  void *validation_ctx = NULL;
  void *request_bytes = NULL;
  int request_len = 0;
  ret = NACInit([certData bytes], [certData length], &validation_ctx,
                &request_bytes, &request_len);
  if (ret != 0) {
    NSLog(@"NACInit failed: %d", ret);
    exit(-1);
    //printf("got unexpected result from valid cert test: %d\n", ret);
  }
  NSLog(@"Validation context initialized!");

  // printf("validation_ctx: %p\n", validation_ctx);

  NSData *request = [[NSData alloc] initWithBytes:request_bytes
                                           length:request_len];
  // printf("request bytes %s\n", [[request description] UTF8String]);

  NSLog(@"Requesting session info...");
  NSData *session_info = initialize_validation(request);
  NSLog(@"Got session info!");
  // printf("session_info bytes %s\n", [[session_info description] UTF8String]);

  // NSData *response = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
  NSLog(@"Submitting session info...");
  ret = NACSubmitResponse(validation_ctx, (void *)[session_info bytes],
                          [session_info length]);
  if (ret != 0) {
    NSLog(@"NACSubmitResponse failed: %d", ret);
    exit(-1);
    //printf("got unexpected result from valid response test: %d\n", ret);
  }
  NSLog(@"Session info submitted!");

  void *validation_data = NULL;
  int validation_data_len = 0;
  NSLog(@"Generating validation data...");
  ret = NACGenerateValidationData(validation_ctx, 0, 0, &validation_data,
                                  &validation_data_len);
  if (ret != 0) {
    NSLog(@"NACGenerateValidationData failed: %d", ret);
    exit(-1);
    //printf("got unexpected result from valid validation data test: %d\n", ret);
  }
  NSLog(@"Validation data generated!");

  NSData *validationData = [[NSData alloc] initWithBytes:validation_data
                                                  length:validation_data_len];

  // Print the base64 encoded validation data
  printf("%s\n", [[validationData base64Encoding] UTF8String]);
}
