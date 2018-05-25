#import <WMF/EventLoggingFunnel.h>
#import <WMF/EventLogger.h>
#import <WMF/SessionSingleton.h>
#import <WMF/WMF-Swift.h>

EventLoggingCategory const EventLoggingCategoryFeed = @"feed";
EventLoggingCategory const EventLoggingCategoryHistory = @"history";
EventLoggingCategory const EventLoggingCategoryPlaces = @"places";
EventLoggingCategory const EventLoggingCategoryArticle = @"article";
EventLoggingCategory const EventLoggingCategorySearch = @"search";
EventLoggingCategory const EventLoggingCategoryAddToList = @"add_to_list";
EventLoggingCategory const EventLoggingCategorySaved = @"saved";
EventLoggingCategory const EventLoggingCategoryLogin = @"login";
EventLoggingCategory const EventLoggingCategorySetting = @"setting";
EventLoggingCategory const EventLoggingCategoryLoginToSyncPopover = @"login_to_sync_popover";
EventLoggingCategory const EventLoggingCategoryEnableSyncPopover = @"enable_sync_popover";
EventLoggingCategory const EventLoggingCategoryUnknown = @"unknown";

EventLoggingLabel const EventLoggingLabelFeaturedArticle = @"featured_article";
EventLoggingLabel const EventLoggingLabelTopRead = @"top_read";
EventLoggingLabel const EventLoggingLabelReadMore = @"read_more";
EventLoggingLabel const EventLoggingLabelRandom = @"random";
EventLoggingLabel const EventLoggingLabelNews = @"news";
EventLoggingLabel const EventLoggingLabelOnThisDay = @"on_this_day";
EventLoggingLabel const EventLoggingLabelRelatedPages = @"related_pages";
EventLoggingLabel const EventLoggingLabelArticleList = @"article_list";
EventLoggingLabel const EventLoggingLabelOutLink = @"out_link";
EventLoggingLabel const EventLoggingLabelSimilarPage = @"similar_page";
EventLoggingLabel const EventLoggingLabelItems = @"items";
EventLoggingLabel const EventLoggingLabelLists = @"lists";
EventLoggingLabel const EventLoggingLabelDefault = @"default";
EventLoggingLabel const EventLoggingLabelSyncEducation = @"sync_education";
EventLoggingLabel const EventLoggingLabelLogin = @"login";
EventLoggingLabel const EventLoggingLabelSyncArticle = @"sync_article";
EventLoggingLabel const EventLoggingLabelLocation = @"location";
EventLoggingLabel const EventLoggingLabelMainPage = @"main_page";

@implementation EventLoggingFunnel

- (id)initWithSchema:(NSString *)schema version:(int)revision {
    if (self) {
        self.schema = schema;
        self.revision = revision;
        self.rate = 1;
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    return eventData;
}

- (void)log:(NSDictionary *)eventData {
    NSString *wiki = [self.primaryLanguage stringByAppendingString:@"wiki"];
    [self log:eventData wiki:wiki];
}

- (void)log:(NSDictionary *)eventData language:(nullable NSString *)language {
    if (language) {
        NSString *wiki = [language stringByAppendingString:@"wiki"];
        [self log:eventData wiki:wiki];
    } else {
        [self log:eventData];
    }
}

- (void)log:(NSDictionary *)eventData wiki:(NSString *)wiki {
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        BOOL chosen = NO;
        if (self.rate == 1) {
            chosen = YES;
        } else if (self.rate != 0) {
            chosen = (self.getEventLogSamplingID % self.rate) == 0;
        }
        if (chosen) {
            NSMutableDictionary *preprocessedEventData = [[self preprocessData:eventData] mutableCopy];
            (void)[[EventLogger alloc] initAndLogEvent:preprocessedEventData
                                             forSchema:self.schema
                                              revision:self.revision
                                                  wiki:wiki];
            [self logged:eventData];
        }
    }
}

- (NSString *)primaryLanguage {
    NSString *primaryLanguage = @"en";
    MWKLanguageLink *appLanguage = [MWKLanguageLinkController sharedInstance].appLanguage;
    if (appLanguage) {
        primaryLanguage = appLanguage.languageCode;
    }
    assert(primaryLanguage);
    return primaryLanguage;
}

- (NSString *)singleUseUUID {
    return [[NSUUID UUID] UUIDString];
}

- (void)logged:(NSDictionary *)eventData {
}

- (NSString *)appInstallID {
    return [[KeychainCredentialsManager shared] appInstallID];
}

- (NSString *)sessionID {
    return [[KeychainCredentialsManager shared] sessionID];
}

- (NSString *)timestamp {
    return [[NSDateFormatter wmf_rfc3339LocalTimeZoneFormatter] stringFromDate:[NSDate date]];
}

- (NSNumber *)isAnon {
    BOOL isAnon = ![WMFAuthenticationManager sharedInstance].isLoggedIn;
    return [NSNumber numberWithBool:isAnon];
}

/**
 *  Persistent random integer id used for sampling.
 *
 *  @return integer sampling id
 */
- (NSInteger)getEventLogSamplingID {
    NSNumber *samplingId = [[NSUserDefaults wmf_userDefaults] objectForKey:@"EventLogSamplingID"];
    if (!samplingId) {
        NSInteger intId = arc4random_uniform(UINT32_MAX);
        [[NSUserDefaults wmf_userDefaults] setInteger:intId forKey:@"EventLogSamplingID"];
        return intId;
    } else {
        return samplingId.integerValue;
    }
}

@end
