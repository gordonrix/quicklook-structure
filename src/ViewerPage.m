#import "ViewerPage.h"

static NSString *const kArgsMarker = @"/*__ARGS__*/";

static NSError *SPError(NSString *msg) {
    return [NSError errorWithDomain:@"StructurePreview" code:1
                           userInfo:@{NSLocalizedDescriptionKey: msg}];
}

NSString *SPViewerPageHTML(NSURL *url, NSError **error) {
    static NSString *head, *tail;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSURL *t = [NSBundle.mainBundle URLForResource:@"viewer" withExtension:@"html"];
        NSString *template = t ? [NSString stringWithContentsOfURL:t encoding:NSUTF8StringEncoding error:nil] : nil;
        NSRange r = template ? [template rangeOfString:kArgsMarker] : NSMakeRange(NSNotFound, 0);
        if (r.location != NSNotFound) {
            head = [template substringToIndex:r.location];
            tail = [template substringFromIndex:NSMaxRange(r)];
        }
    });
    if (!head) {
        if (error) *error = SPError(@"viewer.html is missing from the bundle");
        return nil;
    }

    NSString *text = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]
        ?: [NSString stringWithContentsOfURL:url encoding:NSISOLatin1StringEncoding error:error];
    if (!text) return nil;

    NSString *ext = url.pathExtension.lowercaseString;
    NSString *fmt = ([ext isEqualToString:@"cif"] || [ext isEqualToString:@"mmcif"]) ? @"cif" : @"pdb";
    // NSJSONSerialization escapes "/" as "\/", so a "</script>" inside the
    // file can't close the script tag early.
    NSData *json = [NSJSONSerialization dataWithJSONObject:@{
        @"name": url.lastPathComponent, @"fmt": fmt, @"data": text,
    } options:0 error:error];
    if (!json) return nil;

    NSMutableString *page = [NSMutableString stringWithCapacity:head.length + json.length + tail.length];
    [page appendString:head];
    [page appendString:[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding]];
    [page appendString:tail];
    return page;
}
