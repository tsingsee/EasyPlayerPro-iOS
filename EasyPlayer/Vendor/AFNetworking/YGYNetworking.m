//
//  YGYNetworking.m
//  AFNetworking
//
//  Created by 尹更跃 on 16/03/08.
//  Copyright © 2015年 尹更跃. All rights reserved.
//

#import "YGYNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager.h"

// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define YGYAppLog(s, ... ) NSLog( @"[%@：in line: %d]-->%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define YGYAppLog(s, ... )
#endif

static NSString *sg_privateNetworkBaseUrl = nil;
static BOOL sg_isEnableInterfaceDebug = NO;
static BOOL sg_shouldAutoEncode = NO;
static NSDictionary *sg_httpHeaders = nil;
static YGYResponseType sg_responseType = kYGYResponseTypeJSON;
static YGYRequestType  sg_requestType  = kYGYRequestTypeJSON;

@implementation YGYNetworking

+ (void)updateBaseUrl:(NSString *)baseUrl {
  sg_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
  return sg_privateNetworkBaseUrl;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
  sg_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
  return sg_isEnableInterfaceDebug;
}

+ (void)configResponseType:(YGYResponseType)responseType {
  sg_responseType = responseType;
}

+ (void)configRequestType:(YGYRequestType)requestType {
  sg_requestType = requestType;
}

+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode {
  sg_shouldAutoEncode = shouldAutoEncode;
}

+ (BOOL)shouldEncode {
  return sg_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
  sg_httpHeaders = httpHeaders;
}

+ (YGYURLSessionTask *)getWithUrl:(NSString *)url
                          success:(YGYResponseSuccess)success
                             fail:(YGYResponseFail)fail {
  return [self getWithUrl:url params:nil success:success fail:fail];
}

+ (YGYURLSessionTask *)getWithUrl:(NSString *)url
                           params:(NSDictionary *)params
                          success:(YGYResponseSuccess)success
                             fail:(YGYResponseFail)fail {
  return [self getWithUrl:url params:params progress:nil success:success fail:fail];
}

+ (YGYURLSessionTask *)getWithUrl:(NSString *)url
                           params:(NSDictionary *)params
                         progress:(YGYGetProgress)progress
                          success:(YGYResponseSuccess)success
                             fail:(YGYResponseFail)fail {
  return [self _requestWithUrl:url
                     httpMedth:1
                        params:params
                      progress:progress
                       success:success
                          fail:fail];
}

+ (YGYURLSessionTask *)postWithUrl:(NSString *)url
                            params:(NSDictionary *)params
                           success:(YGYResponseSuccess)success
                              fail:(YGYResponseFail)fail {
  return [self postWithUrl:url params:params progress:nil success:success fail:fail];
}

+ (YGYURLSessionTask *)postWithUrl:(NSString *)url
                            params:(NSDictionary *)params
                          progress:(YGYPostProgress)progress
                           success:(YGYResponseSuccess)success
                              fail:(YGYResponseFail)fail {
  return [self _requestWithUrl:url
                     httpMedth:2
                        params:params
                      progress:progress
                       success:success
                          fail:fail];
}

+ (YGYURLSessionTask *)_requestWithUrl:(NSString *)url
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                              progress:(YGYDownloadProgress)progress
                               success:(YGYResponseSuccess)success
                                  fail:(YGYResponseFail)fail {
  AFHTTPSessionManager *manager = [self manager];
  
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  YGYURLSessionTask *session = nil;
  
  if (httpMethod == 1) {
    session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:task.response.URL.absoluteString
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      if (fail) {
        fail(error);
      }
      
      if ([self isDebug]) {
        [self logWithFailError:error url:task.response.URL.absoluteString params:params];
      }
    }];
  } else if (httpMethod == 2) {
    session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:task.response.URL.absoluteString
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      if (fail) {
        fail(error);
      }
      
      if ([self isDebug]) {
        [self logWithFailError:error url:task.response.URL.absoluteString params:params];
      }
    }];
  }
  
  return session;
}

+ (YGYURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(YGYUploadProgress)progress
                                 success:(YGYResponseSuccess)success
                                    fail:(YGYResponseFail)fail {
  if ([NSURL URLWithString:uploadingFile] == nil) {
    YGYAppLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
    return nil;
  }
  
  NSURL *uploadURL = nil;
  if ([self baseUrl] == nil) {
    uploadURL = [NSURL URLWithString:url];
  } else {
    uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
  }
  
  if (uploadURL == nil) {
    YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
    return nil;
  }
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  AFHTTPSessionManager *manager = [self manager];
  NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
  YGYURLSessionTask *session = [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    [self successResponse:responseObject callback:success];
    
    if (error) {
      if (fail) {
        fail(error);
      }
      
      if ([self isDebug]) {
        [self logWithFailError:error url:response.URL.absoluteString params:nil];
      }
    } else {
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:response.URL.absoluteString
                              params:nil];
      }
    }
  }];
  
  return session;
}

+ (YGYURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(YGYUploadProgress)progress
                               success:(YGYResponseSuccess)success
                                  fail:(YGYResponseFail)fail {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  AFHTTPSessionManager *manager = [self manager];
  YGYURLSessionTask *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
    
    NSString *imageFileName = filename;
    if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      NSString *str = [formatter stringFromDate:[NSDate date]];
      imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
    }
    
    // 上传图片，以文件流的格式
    [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
  } progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    [self successResponse:responseObject callback:success];
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject
                               url:task.response.URL.absoluteString
                            params:parameters];
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    if (fail) {
      fail(error);
    }
    
    if ([self isDebug]) {
      [self logWithFailError:error url:task.response.URL.absoluteString params:nil];
    }
  }];
  
  return session;
}

+ (YGYURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(YGYDownloadProgress)progressBlock
                               success:(YGYResponseSuccess)success
                               failure:(YGYResponseFail)failure {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      YGYAppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  AFHTTPSessionManager *manager = [self manager];
  
  YGYURLSessionTask *session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
    if (progressBlock) {
      progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
    }
  } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
    return [NSURL URLWithString:saveToPath];
  } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
    if (success) {
      success(filePath.absoluteString);
    }
  }];
  
  return session;
}

#pragma mark - Private
+ (AFHTTPSessionManager *)manager {
  // 开启转圈圈
  [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
  
  AFHTTPSessionManager *manager = nil;;
  if ([self baseUrl] != nil) {
    manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
  } else {
    manager = [AFHTTPSessionManager manager];
  }
  
  switch (sg_requestType) {
    case kYGYRequestTypeJSON: {
      manager.requestSerializer = [AFJSONRequestSerializer serializer];
      [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
      [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
      break;
    }
    case kYGYRequestTypePlainText: {
      manager.requestSerializer = [AFHTTPRequestSerializer serializer];
      break;
    }
    default: {
      break;
    }
  }
  
  switch (sg_responseType) {
    case kYGYResponseTypeJSON: {
      manager.responseSerializer = [AFJSONResponseSerializer serializer];
      break;
    }
    case kYGYResponseTypeXML: {
      manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
      break;
    }
    case kYGYResponseTypeData: {
      manager.responseSerializer = [AFHTTPResponseSerializer serializer];
      break;
    }
    default: {
      break;
    }
  }
  
  manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
  
  
  for (NSString *key in sg_httpHeaders.allKeys) {
    if (sg_httpHeaders[key] != nil) {
      [manager.requestSerializer setValue:sg_httpHeaders[key] forHTTPHeaderField:key];
    }
  }
  manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                            @"text/html",
                                                                            @"text/json",
                                                                            @"text/plain",
                                                                            @"text/javascript",
                                                                            @"text/xml",
                                                                            @"image/*"]];
  
  // 设置允许同时最大并发数量，过大容易出问题
  manager.operationQueue.maxConcurrentOperationCount = 3;
  return manager;
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
  YGYAppLog(@"\nabsoluteUrl: %@\n params:%@\n response:%@\n\n",
            [self generateGETAbsoluteURL:url params:params],
            params,
            [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(NSDictionary *)params {
  YGYAppLog(@"\nabsoluteUrl: %@\n params:%@\n errorInfos:%@\n\n",
            [self generateGETAbsoluteURL:url params:params],
            params,
            [error localizedDescription]);
}

// 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(NSDictionary *)params {
  if (params.count == 0) {
    return url;
  }
  
  NSString *queries = @"";
  for (NSString *key in params) {
    id value = [params objectForKey:key];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
      continue;
    } else if ([value isKindOfClass:[NSArray class]]) {
      continue;
    } else if ([value isKindOfClass:[NSSet class]]) {
      continue;
    } else {
      queries = [NSString stringWithFormat:@"%@%@=%@&",
                 (queries.length == 0 ? @"&" : queries),
                 key,
                 value];
    }
  }
  
  if (queries.length > 1) {
    queries = [queries substringToIndex:queries.length - 1];
  }
  
  if (([url rangeOfString:@"http://"].location != NSNotFound
      || [url rangeOfString:@"https://"].location != NSNotFound)
      && queries.length > 1) {
    if ([url rangeOfString:@"?"].location != NSNotFound
        || [url rangeOfString:@"#"].location != NSNotFound) {
      url = [NSString stringWithFormat:@"%@%@", url, queries];
    } else {
      queries = [queries substringFromIndex:1];
      url = [NSString stringWithFormat:@"%@?%@", url, queries];
    }
  }
  
  return url.length == 0 ? queries : url;
}


+ (NSString *)encodeUrl:(NSString *)url {
  return [self ygy_URLEncode:url];
}

+ (id)tryToParseData:(id)responseData {
  if ([responseData isKindOfClass:[NSData class]]) {
    // 尝试解析成JSON
    if (responseData == nil) {
      return responseData;
    } else {
      NSError *error = nil;
      NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
      
      if (error != nil) {
        return responseData;
      } else {
        return response;
      }
    }
  } else {
    return responseData;
  }
}

+ (void)successResponse:(id)responseData callback:(YGYResponseSuccess)success {
  if (success) {
    success([self tryToParseData:responseData]);
  }
}

+ (NSString *)ygy_URLEncode:(NSString *)url {
  NSString *newString =
  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                            (CFStringRef)url,
                                                            NULL,
                                                            CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
  if (newString) {
    return newString;
  }
  
  return url;
}

@end
