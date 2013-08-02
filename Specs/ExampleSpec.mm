#import <objc/objc-runtime.h>
using namespace Cedar::Matchers;

using namespace Cedar::Doubles;

@interface Person : NSObject

- (void)sayHello;

@end


@implementation Person

- (void)sayHello {
	NSLog(@"hello");
}

- (void)skew:(int)n {
	NSLog(@"skew %d", n);
}

@end

@interface Book : NSObject

- (void)foo;
- (void)bar;

@end

@implementation Book

- (void)foo;
{
    NSLog(@"foo");
    [self bar];
}

- (void)bar;
{
    NSLog(@"bar");
}

- (void)baz;
{
    NSLog(@"baz");
}

+ (BOOL) resolveInstanceMethod:(SEL)aSEL
{
    NSLog(@"resolvedInstanceMethod: %@", NSStringFromSelector(aSEL));
    return [super resolveInstanceMethod:aSEL];
}

@end

static IMP originalPaste = NULL;

void myPaste(id rcv, SEL cmd)
{
    NSLog(@"myPaste");
    // Your implementation here
}

SPEC_BEGIN(ExampleSpec)

/* This is not an exhaustive list of usages.
   For more information, please visit https://github.com/pivotal/cedar */


describe(@"Example specs on NSString", ^{

    it(@"lowercaseString returns a new string with everything in lower case", ^{
        [@"FOOBar" lowercaseString] should equal(@"foobar");
    });

    it(@"length returns the number of characters in the string", ^{
        [@"internationalization" length] should equal(20);
    });

    describe(@"isEqualToString:", ^{
        it(@"should return true if the strings are the same", ^{
            [@"someString" isEqualToString:@"someString"] should be_truthy;
        });

        it(@"should return false if the strings are not the same", ^{
            [@"someString" isEqualToString:@"anotherString"] should_not be_truthy;
        });
    });

    describe(@"NSMutableString", ^{
        it(@"should be a kind of NSString", ^{
            [NSMutableString string] should be_instance_of([NSString class]).or_any_subclass();
        });
    });
    
    describe(@"Book", ^{
        it(@"should return class name", ^{
            NSLog(@"class name: %s", class_getName([Book class]));
            NSLog(@"super class name: %s", class_getName(class_getSuperclass([Book class])));
        });
        
        it(@"should replace one method with another method", ^{
            Book *book = [[Book alloc] init];
            Method bar = class_getInstanceMethod([book class], @selector(bar));
            Method baz = class_getInstanceMethod([book class], @selector(baz));
            
            IMP imp = method_getImplementation(baz);
            
            [book bar];
            method_setImplementation(bar, imp);
            [book bar];
            [book baz];
        });
        
        it(@"should replace method with function", ^{
            Book *book = [[Book alloc] init];
            Book *book2 = [[Book alloc] init];
            Method bar = class_getInstanceMethod([book class], @selector(bar));
            
            [book bar];
            IMP old = method_setImplementation(bar, (IMP)myPaste);
            [book bar];
            [book baz];
            method_setImplementation(bar, old);
            [book2 bar];
        });
        
        it(@"should replace method with block", ^{
            Person *person = [[Person alloc] init];
            [person sayHello];
            
            IMP a = imp_implementationWithBlock(^{
                NSLog(@"hello again");
            });
            
            class_replaceMethod([Person class], @selector(sayHello), a, NULL);
            
            [person sayHello];
        });
        
        fit(@"should replace method with block with arguments", ^{
            Person *person = [[Person alloc] init];
            [person skew:1];
            
            IMP skewIMP = imp_implementationWithBlock(^(id _s, int k) { NSLog(@"block skew %d", k); });
            
            class_replaceMethod([Person class], @selector(skew:), skewIMP, "v@:i");
            
            [person skew:9];
        });
    });
    
});

SPEC_END
