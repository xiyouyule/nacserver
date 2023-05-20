#import <dlfcn.h>
#import <stdio.h>

#import "nac.m"
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOCFSerialize.h>
#import <IOKit/IOKitLib.h>

// Requests the validation certificate chain from Apple
// http://static.ess.apple.com/identity/validation/cert-1.0.plist
NSData *request_cert() {
  return [NSDictionary
      dictionaryWithContentsOfURL:
          [NSURL URLWithString:@"http://static.ess.apple.com/identity/"
                               @"validation/cert-1.0.plist"]][@"cert"];
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

int main() {

  // hello();
  // CFTypeRef test = IORegistryEntryCreateCFProperty();
  NSLog(@"Sanity checking NACInit...");
  int ret = NACInit(0, 0, 0, 0, 0);
  if (ret != -44023) {
    NSLog(@"NACInit failed sanity check, returned %d", ret);
    exit(-1);
    // printf("got unexpected result from all-null test: %d\n", ret);
  }
  NSLog(@"NACInit sanity check passed!");

  NSLog(@"Requesting cert...");
  NSData *certData = request_cert();
  NSLog(@"Got cert! %@", certData);

  NSLog(@"Initializing validation context...");
  void *validation_ctx = NULL;
  void *request_bytes = NULL;
  int request_len = 0;
  ret = NACInit([certData bytes], [certData length], &validation_ctx,
                &request_bytes, &request_len);
  if (ret != 0) {
    NSLog(@"NACInit failed: %d", ret);
    exit(-1);
    // printf("got unexpected result from valid cert test: %d\n", ret);
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
  ret = NACSubmit(validation_ctx, (void *)[session_info bytes],
                  [session_info length]);
  if (ret != 0) {
    NSLog(@"NACSubmitResponse failed: %d", ret);
    exit(-1);
    // printf("got unexpected result from valid response test: %d\n", ret);
  }
  NSLog(@"Session info submitted!");

  void *validation_data = NULL;
  int validation_data_len = 0;
  NSLog(@"Generating validation data...");
  ret =
      NACGenerate(validation_ctx, 0, 0, &validation_data, &validation_data_len);
  if (ret != 0) {
    NSLog(@"NACGenerateValidationData failed: %d", ret);
    exit(-1);
    // printf("got unexpected result from valid validation data test: %d\n",
    // ret);
  }
  NSLog(@"Validation data generated!");

  NSData *validationData = [[NSData alloc] initWithBytes:validation_data
                                                  length:validation_data_len];

  // Print the base64 encoded validation data
  printf("%s\n", [[validationData base64Encoding] UTF8String]);
}
