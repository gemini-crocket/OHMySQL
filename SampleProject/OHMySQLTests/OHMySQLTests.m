//
// Copyright (c) 2015-Present Oleg Hnidets
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//


/* Note:
    Unit tests must be refactored and separated by functionlities and classes.
    Current implementation is massive and doesn't apply to best practises.
    It were my first unit tests that's why they are ugly.
 */


@import XCTest;
#import "XCTestCase+Database_Basic.h"

@interface OHMySQLTests : XCTestCase

@end

@implementation OHMySQLTests

#pragma mark - setup

- (void)setUp {
    [super setUp];
    [OHMySQLTests configureDatabase];
    
    [self createTable];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Testing

- (void)testSelectDatabase {
    [self dropTableNamed:kTableName];
    
    // when
    OHResultErrorType result = [self.storeCoordinator selectDataBase:kDatabaseName];
    
    // then
    XCTAssert(result == OHResultErrorTypeNone);
}

- (void)testInsertNewRow {
    // given
    NSDictionary *insertSet = @{ @"name" : @"Oleg", @"surname" : @"Hnidets", @"age" : @"21" };
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory INSERT:kTableName
                                                                       set:insertSet];
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success);
    AssertIfError();
    
    // when
    NSInteger lastInsertedID = [self.mainQueryContext lastInsertID].integerValue;
    // then
    XCTAssert(lastInsertedID > 0);
}

- (void)testUpdateAll {
    // given
    NSDictionary *updateSet = @{ @"name" : @"Oleg", @"surname" : @"Hnidets", @"age" : @"21" };
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory UPDATE:kTableName
                                                                       set:updateSet
                                                                 condition:nil];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success);
    AssertIfError();
}

- (void)testAffectedRows {
    // when
    NSInteger numberOfRows = [self.mainQueryContext affectedRows].integerValue;
    XCTAssert(numberOfRows != -1);
}

- (void)testCountRecords {
    // when
    NSNumber *countOfObjects = [self countOfObjects];
    // then
    XCTAssertNotEqualObjects(countOfObjects, @0);
}

- (void)testUpdateAllWithCondition {
    // given
    [self testInsertNewRow];
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory UPDATE:kTableName set:@{ @"age" : @"25" } condition:@"name='Oleg'"];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success);
    AssertIfError();
}

- (void)testDeleAllWithCondition {
    // given
    [self testInsertNewRow];
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory DELETE:kTableName condition:@"name='Oleg'"];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    
    // then
    XCTAssert(success);
    AssertIfError();
}

- (void)testRefresh {
    // when
    [self testInsertNewRow];
    OHResultErrorType result = [self.storeCoordinator refresh:OHRefreshOptionTables];
    // then
    XCTAssert(result == OHResultErrorTypeNone);
}

- (void)testDeleteAllRecords {
    // given
    [self testInsertNewRow];
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory DELETE:kTableName condition:nil];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success);
    AssertIfError();
}

- (void)testDropTable {
    // given
    OHMySQLQueryRequest *queryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:kDropTableString];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success);
    AssertIfError();
    
    // when
    CFAbsoluteTime totalTime = queryRequest.timeline.totalTime;
    // then
    XCTAssert(totalTime > 0);
}

- (void)testIncorrectPlainQuery {
    // given
    NSString *incorrectQueryString = [kDropTableString stringByReplacingOccurrencesOfString:@"TABLE" withString:@"TABL"];
    OHMySQLQueryRequest *queryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:incorrectQueryString];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    XCTAssert(success == NO);
    AssertIfNoError();
}

- (void)testIncorrectSelectQuery {
    // given
    NSString *incorrectQueryString = @"SELECT qwe FROM 'something'";
    OHMySQLQueryRequest *queryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:incorrectQueryString];
    
    // when
    NSError *error;
    NSArray *response = [self.mainQueryContext executeQueryRequestAndFetchResult:queryRequest error:&error];
    // then
    XCTAssert(response == nil);
    AssertIfNoError();
}

- (void)testStoreInformation {
    // given
    OHMySQLStore *store = self.storeCoordinator.store;
    // then
    XCTAssert(store.serverInfo && store.hostInfo && store.protocolInfo && store.serverVersion && store.status);
}

- (void)testNotConnected {
    // given
    [self.storeCoordinator disconnect];
    OHMySQLQueryRequest *queryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:kDropTableString];
    
    // when
    NSError *error;
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    // then
    AssertIfError();
    XCTAssert(success == YES);
}

- (void)testCheckConnection {
    // given
    [self.storeCoordinator disconnect];
    
    // when
    BOOL isConnected = self.storeCoordinator.isConnected;
    // then
    XCTAssert(isConnected == NO);
}

- (void)DISABLED_test24ShutdownDatabase {
    // when
    OHResultErrorType result = [self.storeCoordinator shutdown];
    // then
    XCTAssert(result == OHResultErrorTypeNone);
}

@end
