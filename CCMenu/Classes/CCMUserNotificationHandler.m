
#import "CCMServerMonitor.h"
#import "CCMUserNotificationHandler.h"
#import "NSWorkspace+CCMAdditions.h"


@implementation CCMUserNotificationHandler

+ (NSDictionary *)detailsForBuildResult:(NSString *)buildResult
{
    NSDictionary *allDetails = @{
        CCMSuccessfulBuild: @{
            @"title": NSLocalizedString(@"Success", "Notification for successful build"),
            @"text": NSLocalizedString(@"Yet another successful build!", "For notificiation")
        },
        CCMStillFailingBuild: @{
            @"title": NSLocalizedString(@"Still broken", "Notification for repeatedly broken build"),
            @"text": NSLocalizedString(@"The build is still broken.", "For notificiation")
        },
        CCMBrokenBuild: @{
            @"title": NSLocalizedString(@"Broken", "Notification for broken build"),
            @"text": NSLocalizedString(@"Recent checkins have broken the build.", "For notificiation")
        },
        CCMFixedBuild: @{
            @"title": NSLocalizedString(@"Fixed", "Notification for just fixed build"),
            @"text": NSLocalizedString(@"Recent checkins have fixed the build.", "For notificiation")
        },
        @"Starting" : @{
            @"title": NSLocalizedString(@"Starting", "Notification for build starting"),
            @"text": NSLocalizedString(@"A build has started on the server.", "For notificiation")
        }
    };
    return [allDetails objectForKey:buildResult];
}

- (void)start
{
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(buildComplete:) name:CCMBuildStartNotification object:nil];
	[[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(buildComplete:) name:CCMBuildCompleteNotification object:nil];
    [[NSUserNotificationCenter defaultUserNotificationCenter]
     setDelegate:self];
}


- (void)buildComplete:(NSNotification *)buildNotification
{
	NSString *projectName = [[buildNotification object] name];
    NSString *buildResult = [[buildNotification userInfo] objectForKey:@"buildResult"] ?: @"Starting";
	NSString *webUrl = [[buildNotification userInfo] objectForKey:@"webUrl"];

    NSDictionary *details = [[self class] detailsForBuildResult:buildResult];
    if(details == nil)
        return;

    NSString *soundName = [defaultsManager soundForEvent:buildResult];
    if([defaultsManager shouldSendUserNotificationForEvent:buildResult])
    {
        NSUserNotification *userNotification = [[[NSUserNotification alloc] init] autorelease];
        userNotification.title = [NSString stringWithFormat:@"%@: %@", projectName, [details objectForKey:@"title"]];
        userNotification.informativeText = [details objectForKey:@"text"];
        if(soundName != nil)
            userNotification.soundName = soundName;
        if(webUrl != nil)
            userNotification.userInfo = [NSDictionary dictionaryWithObject:webUrl forKey:@"webUrl"];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
    }
    else
    {
        if(soundName != nil)
            [[NSSound soundNamed:soundName] play];
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    [self openURLForNotification:notification];
}

- (void)openURLForNotification:(NSUserNotification *)notification
{
    NSString *webUrl = [notification.userInfo objectForKey:@"webUrl"];
    if(webUrl != nil)
    {
        [[NSWorkspace sharedWorkspace] openURLString:webUrl];
    }
}


@end
