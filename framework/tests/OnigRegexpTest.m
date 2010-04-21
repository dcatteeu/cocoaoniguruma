#import "OnigRegexpTest.h"
#import "CocoaOniguruma/OnigRegexp.h"


@implementation OnigRegexpTest

- (void)testSurrogatePairs
{
	OnigRegexp* e = [OnigRegexp compile:@"[^a-z0-9_\\s]"];
	OnigResult* r = [e search:[NSString stringWithUTF8String:"012_\xf0\xa3\x8f\x90 abc"]];
	
	STAssertNotNil(r, nil);
	STAssertEquals([r bodyRange], NSMakeRange(4,2), nil);
	STAssertEqualObjects([r body], [NSString stringWithUTF8String:"\xf0\xa3\x8f\x90"], nil);
	STAssertEqualObjects([r preMatch], @"012_", nil);
	STAssertEqualObjects([r postMatch], @" abc", nil);
}

- (void)testNamedCaptures
{
	OnigRegexp* e = [OnigRegexp compile:@"(?<digits>\\d+)[^\\d]+(?<digits>\\d+)[^a-zA-Z\\d]*(?<letters>[a-zA-Z]+)"];
	OnigResult* r = [e search:@"  012/345  \\t  abc##"];
	
	STAssertNotNil(r, nil);
	STAssertEquals(NSMakeRange(2,11), [r bodyRange], nil);
	STAssertEquals([r count], 4, nil);
	STAssertEquals([r indexForName:@"digits"], 1, nil);
	STAssertEqualObjects([r indexesForName:@"digits"], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,2)], nil);
	STAssertEquals([r indexForName:@"letters"], 3, nil);
	STAssertEqualObjects([r indexesForName:@"letters"], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3,1)], nil);
	STAssertEqualObjects([r stringForName:@"digits"], @"012", nil);
	
	NSArray* ary = [r stringsForName:@"digits"];
	NSArray* expected = [NSArray arrayWithObjects:@"012", @"345", nil];
	STAssertEqualObjects(ary, expected, nil);
}

- (void)testSearch
{
	OnigRegexp* e = [OnigRegexp compile:@"[a-z]+"];
	OnigResult* r = [e search:@" 012xyz abc789"];
	
	STAssertEquals([r bodyRange], NSMakeRange(4,3), nil);
	STAssertEqualObjects([r body], @"xyz", nil);
}

- (void)testMatch
{
	OnigRegexp* e = [OnigRegexp compile:@"[a-z]+"];
	OnigResult* r = [e match:@"abcABC"];
	
	STAssertEquals(NSMakeRange(0,3), [r bodyRange], nil);
	STAssertEqualObjects(@"abc", [r body], nil);
}

- (void)testRangeOfRegexp
{
	STAssertEquals([@"" rangeOfRegexp:@"^"], NSMakeRange(0,0), nil);
	STAssertEquals([@"" rangeOfRegexp:[OnigRegexp compile:@"^"]], NSMakeRange(0,0), nil);
	STAssertEquals([@" 0 abc xyz" rangeOfRegexp:@"[a-z]+"], NSMakeRange(3,3), nil);
	STAssertEquals([@" 0 abc xyz" rangeOfRegexp:[OnigRegexp compile:@"[a-z]+"]], NSMakeRange(3,3), nil);
	STAssertEquals([@"abc" rangeOfRegexp:@"[^a-z]+"], NSMakeRange(NSNotFound,0), nil);
	STAssertEquals([@"abc" rangeOfRegexp:[OnigRegexp compile:@"[^a-z]+"]], NSMakeRange(NSNotFound,0), nil);
}

// These tests are based on ruby 1.8's source code.

- (void)testSplit
{
	NSArray* expected;
	
	expected = [NSArray arrayWithObjects:@"now's", @"the", @"time", nil];
	STAssertEqualObjects([@" now's  the time" split], expected, nil);
	STAssertEqualObjects([@" now's  the time" splitByRegexp:@" "], expected, nil);
	expected = [NSArray arrayWithObjects:@"", @"now's", @"", @"the", @"time", nil];
	STAssertEqualObjects([@" now's  the time" splitByRegexp:[OnigRegexp compile:@" "]], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"1", @"2.34", @"56", @"7", nil];
	STAssertEqualObjects([@"1, 2.34,56, 7" splitByRegexp:@",\\s*"], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"h", @"e", @"l", @"l", @"o", nil];
	STAssertEqualObjects([@"hello" splitByRegexp:@""], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"h", @"e", @"llo", nil];
	STAssertEqualObjects([@"hello" splitByRegexp:@"" limit:3], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"h", @"i", @"m", @"o", @"m", nil];
	STAssertEqualObjects([@"hi mom" splitByRegexp:@"\\s*"], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"m", @"w y", @"w", nil];
	STAssertEqualObjects([@"mellow yellow" splitByRegexp:@"ello"], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"1", @"2", @"", @"3", @"4", nil];
	STAssertEqualObjects([@"1,2,,3,4,," splitByRegexp:@","], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"1", @"2", @"", @"3,4,,", nil];
	STAssertEqualObjects([@"1,2,,3,4,," splitByRegexp:@"," limit:4], expected, nil);
	
	expected = [NSArray arrayWithObjects:@"1", @"2", @"", @"3", @"4", @"", @"", nil];
	STAssertEqualObjects([@"1,2,,3,4,," splitByRegexp:@"," limit:-4], expected, nil);
}

- (void)testReplace
{
	STAssertEqualObjects([@"" replaceByRegexp:@"" with:@""], @"", nil);
	STAssertEqualObjects([@"" replaceByRegexp:@"" with:@"_"], @"_", nil);
	STAssertEqualObjects([@"" replaceByRegexp:@"0" with:@"_"], @"", nil);
	STAssertEqualObjects([@"abc" replaceByRegexp:@"" with:@"_"], @"_abc", nil);
	STAssertEqualObjects([@"abc" replaceByRegexp:@"$" with:@"_"], @"abc_", nil);
	STAssertEqualObjects([@"aa 00 aa 11" replaceByRegexp:@"\\d+" with:@"digits"], @"aa digits aa 11", nil);
}

- (void)testReplaceAll
{
	STAssertEqualObjects([@"abc" replaceAllByRegexp:@"" with:@"_"], @"_a_b_c_", nil);
	STAssertEqualObjects([@"abc" replaceAllByRegexp:@"^" with:@"_"], @"_abc", nil);
	STAssertEqualObjects([@"abc" replaceAllByRegexp:@"$" with:@"_"], @"abc_", nil);
	STAssertEqualObjects([@"abc" replaceAllByRegexp:@"." with:@"_"], @"___", nil);
	STAssertEqualObjects([@"aa 00 aa 11" replaceAllByRegexp:@"\\d+" with:@"digits"], @"aa digits aa digits", nil);
}

@end
