import Testing
@testable import PanelDesignKit

@Suite("Marginal profiles")
struct MarginalTests {

    @Test func countsBecomeAProfile() throws {
        let profile = try MarginalProfile(counts: [7, 3])
        #expect(profile.itemCount == 10)
        #expect(profile.categoryCount == 2)
        #expect(profile.rate(0) == 0.7)
        #expect(!profile.isDegenerate)
        #expect(profile.degenerateCategory == nil)
    }

    @Test func oneCategoryIsRefused() {
        #expect(throws: PanelDesignError.categoryCountTooSmall(1)) {
            _ = try MarginalProfile(counts: [4])
        }
    }

    @Test func negativeCountsAreRefused() {
        #expect(throws: PanelDesignError.negativeCount(category: 1, count: -2)) {
            _ = try MarginalProfile(counts: [6, -2])
        }
    }

    @Test func tooFewItemsIsRefused() {
        #expect(throws: PanelDesignError.itemCountTooSmall(1)) {
            _ = try MarginalProfile(counts: [1, 0])
        }
    }

    @Test func binaryProfileSplitsPositives() throws {
        let profile = try MarginalProfile.binary(positives: 176, items: 200)
        #expect(profile.counts == [176, 24])
    }

    @Test func binaryRefusesImpossibleShapes() {
        #expect(throws: PanelDesignError.itemCountTooSmall(1)) {
            _ = try MarginalProfile.binary(positives: 1, items: 1)
        }
        #expect(throws: PanelDesignError.negativeCount(category: 0, count: -1)) {
            _ = try MarginalProfile.binary(positives: -1, items: 10)
        }
        #expect(throws: PanelDesignError.negativeCount(category: 1, count: -2)) {
            _ = try MarginalProfile.binary(positives: 12, items: 10)
        }
    }

    @Test func labelsBecomeAProfile() throws {
        let profile = try MarginalProfile.fromLabels([0, 1, 1, 2], categoryCount: 3)
        #expect(profile.counts == [1, 2, 1])
    }

    @Test func labelsRefuseBadInput() {
        #expect(throws: PanelDesignError.categoryCountTooSmall(1)) {
            _ = try MarginalProfile.fromLabels([0, 0], categoryCount: 1)
        }
        #expect(throws: PanelDesignError.labelOutOfRange(judge: 3, item: 1, label: 5)) {
            _ = try MarginalProfile.fromLabels([0, 5], categoryCount: 2, judge: 3)
        }
    }

    @Test func aConstantJudgeIsDegenerate() throws {
        let profile = try MarginalProfile(counts: [4, 0])
        #expect(profile.isDegenerate)
        #expect(profile.degenerateCategory == 0)
    }

    @Test func comparabilityIsEnforced() throws {
        let ten = try MarginalProfile(counts: [5, 5])
        let twelve = try MarginalProfile(counts: [6, 6])
        let ternary = try MarginalProfile(counts: [4, 3, 3])
        try MarginalProfile.requireComparable(ten, ten)
        #expect(throws: PanelDesignError.itemCountMismatch(first: 10, second: 12)) {
            try MarginalProfile.requireComparable(ten, twelve)
        }
        #expect(throws: PanelDesignError.categoryCountMismatch(first: 2, second: 3)) {
            try MarginalProfile.requireComparable(ten, ternary)
        }
    }
}
