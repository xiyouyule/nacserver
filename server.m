#include "nac.m"
#include <Foundation/Foundation.h>

NSString *read_until(NSFileHandle *handle, NSString *delim) {
  NSMutableString *str = [NSMutableString string];
  NSData *data = nil;
  while (true) {
    // Read a single byte
    data = [handle readDataOfLength:1];
    if ([data length] == 0) {
      break; // EOF
    }

    NSString *s = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
    if ([s isEqualToString:delim]) {
      break;
    }
    [str appendString:s];
  }
  return str;
}

NSDictionary *handle_command(NSDictionary *cmd) {
  //NSLog(@"Got command: %@", cmd);
  NSString *command = cmd[@"command"];
  // Check if the command is "load"
  if ([command isEqualToString:@"load"]) {
    // Load the IMDAppleServices framework
    @try {
      NACLoad();
    } @catch (NSException *e) {
      NSLog(@"NACLoad threw exception: %@", e);
      return @{
        @"status" : @"error",
        @"error": @"nacload_threw",
        @"description" : [NSString stringWithFormat:@"NACLoad threw exception: %@", e],
      };
    }
    return @{
      @"status" : @"ok",
    };
  } else if ([command isEqualToString:@"init"]) {
    // Get the cert bytes
    NSString *cert = cmd[@"cert"];
    if (!cert) {
      return @{
        @"status" : @"error",
        @"error": @"missing_cert",
        @"description" : @"Missing cert",
      };
    }
    NSData *cert_data = [[NSData alloc] initWithBase64EncodedString:cert
                                                             options:0];
    // Initialize the validation context
    void *validation_ctx = NULL;
    void *request_bytes = NULL;
    int request_len = 0;
    int ret;
    @try {
    ret = NACInit([cert_data bytes], [cert_data length], &validation_ctx,
                      &request_bytes, &request_len);
    } @catch (NSException *e) {
      NSLog(@"NACInit threw exception: %@", e);
      return @{
        @"status" : @"error",
        @"error": @"nacinit_threw",
        @"description" : [NSString stringWithFormat:@"NACInit threw exception: %@", e],
      };
    }

    if (ret != 0) {
      NSLog(@"NACInit failed: %d", ret);
      return @{
        @"status" : @"error",
        @"error": @"nacinit_failed",
        @"description" : [NSString stringWithFormat:@"NACInit failed: %d", ret],
        @"code" : [NSNumber numberWithInt:ret],
      };
    }
    // Return the request bytes
    NSData *request = [[NSData alloc] initWithBytes:request_bytes
                                             length:request_len];
    return @{
      @"status" : @"ok",
      @"context" : [NSString stringWithFormat:@"%p", validation_ctx],
      @"request" : [request base64EncodedStringWithOptions:0],
    };
  } else if ([command isEqualToString:@"submit"]) {
    // Get the validation context
    NSString *context = cmd[@"context"];
    if (!context) {
      return @{
        @"status" : @"error",
        @"error": @"missing_context",
        @"description" : @"Missing context",
      };
    }

    // Parse hex string
    unsigned long long validation_ctx_num;
    NSScanner* scanner = [NSScanner scannerWithString:context];
    [scanner scanHexLongLong:&validation_ctx_num];
    void *validation_ctx = (void *)validation_ctx_num;
    
    NSString *resp = cmd[@"response"];
    if (!resp) {
      return @{
        @"status" : @"error",
        @"error": @"missing_response",
        @"description" : @"Missing response",
      };
    }
    NSData *resp_data = [[NSData alloc] initWithBase64EncodedString:resp
                                                             options:0];

    NSLog(@"Submitting response: %@ with context %p", resp_data, validation_ctx);

    int ret;
    @try {
      ret = NACSubmit(validation_ctx, (void*)[resp_data bytes], [resp_data length]);
    } @catch (NSException *e) {
      NSLog(@"NACSubmit threw exception: %@", e);
      return @{
        @"status" : @"error",
        @"error": @"nacsubmit_threw",
        @"description" : [NSString stringWithFormat:@"NACSubmit threw exception: %@", e],
      };
    }

    if (ret != 0) {
      NSLog(@"NACSubmit failed: %d", ret);
      return @{
        @"status" : @"error",
        @"error": @"nacsubmit_failed",
        @"description" : [NSString stringWithFormat:@"NACSubmit failed: %d", ret],
        @"code" : [NSNumber numberWithInt:ret],
      };
    }

    return @{
      @"status" : @"ok",
    };
  } else if ([command isEqualToString:@"generate"]) {
    // Get context
    NSString *context = cmd[@"context"];
    if (!context) {
      return @{
        @"status" : @"error",
        @"error": @"missing_context",
        @"description" : @"Missing context",
      };
    }

    // Parse hex string
    unsigned long long validation_ctx_num;
    NSScanner* scanner = [NSScanner scannerWithString:context];
    [scanner scanHexLongLong:&validation_ctx_num];
    void *validation_ctx = (void *)validation_ctx_num;

    // Generate the validation data
    void *validation_data = NULL;
    int validation_data_len = 0;
    int ret;
    @try {
      ret = NACGenerate(validation_ctx, 0, 0, &validation_data, &validation_data_len);
    } @catch (NSException *e) {
      NSLog(@"NACGenerate threw exception: %@", e);
      return @{
        @"status" : @"error",
        @"error": @"nacgenerate_threw",
        @"description" : [NSString stringWithFormat:@"NACGenerate threw exception: %@", e],
      };
    }
    if (ret != 0) {
      NSLog(@"NACGenerate failed: %d", ret);
      return @{
        @"status" : @"error",
        @"error": @"nacgenerate_failed",
        @"description" : [NSString stringWithFormat:@"NACGenerate failed: %d", ret],
        @"code" : [NSNumber numberWithInt:ret],
      };
    }

    // Return the validation data
    NSData *data = [[NSData alloc] initWithBytes:validation_data
                                          length:validation_data_len];
    return @{
      @"status" : @"ok",
      @"validation" : [data base64EncodedStringWithOptions:0],
    };
  } 
  else {
    // Unknown command
    return @{
      @"status" : @"error",
      @"error" : @"unk_command",
      @"description" : [NSString stringWithFormat:@"Unknown command: %@", command],
    };
  }
}

int main() {
  NSLog(@"Hello world!");
  // Read JSON commands from stdin and write JSON responses to stdout
  NSFileHandle *stdin = [NSFileHandle fileHandleWithStandardInput];
  NSFileHandle *stdout = [NSFileHandle fileHandleWithStandardOutput];

  while (true) {
    NSString *cmd = read_until(stdin, @"\n");
    if ([cmd length] == 0) {
      break; // EOF
    }

    // Parse the JSON command
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization
        JSONObjectWithData:[cmd dataUsingEncoding:NSUTF8StringEncoding]
                   options:0
                     error:&error];
    if (error) {
      NSLog(@"Failed to parse JSON: %@", error);
      return -1;
    }

    //NSLog(@"Got command: %@", json);
    NSDictionary *response = handle_command(json);
    //NSLog(@"Sending response: %@", response);

    // Write the JSON response
    NSData *data = [NSJSONSerialization dataWithJSONObject:response
                                                   options:0
                                                     error:&error];

    if (error) {
      NSLog(@"Failed to serialize JSON: %@", error);
      return -1;
    }
    [stdout writeData:data];
    // Add a newline
    [stdout writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
  }
}