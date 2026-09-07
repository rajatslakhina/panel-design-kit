import Testing
@testable import PanelDesignKit

@Suite("Attainable agreement")
struct AttainableTests {

    @Test func twoStrictGatesMustAgree() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile.binary(positives: 176, items: 200),
            second: try MarginalProfile.binary(positives: 170, items: 200)
        )
        #expect(range.lowerCount == 146)
        #expect(range.upperCount == 194)
        #expect(range.lower == 0.73)
        #expect(range.upper == 0.97)
        #expect(range.step == 2)
        #expect(range.attainableCounts?.count == 25)
        #expect(!range.isPinned)
        #expect(range.categoryCount == 2)
        #expect(range.itemCount == 200)
    }

    @Test func aConstantJudgePinsTheRate() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile.binary(positives: 200, items: 200),
            second: try MarginalProfile.binary(positives: 130, items: 200)
        )
        #expect(range.isPinned)
        #expect(range.lowerCount == 130)
        #expect(range.attainableCounts == [130])
        #expect(!range.marginsAreIdentical)
    }

    @Test func theLatticeIsCoarserThanOneItem() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile.binary(positives: 121, items: 200),
            second: try MarginalProfile.binary(positives: 110, items: 200)
        )
        #expect(range.step == 2)
        #expect(range.admits(count: 141) == true)
        #expect(range.admits(count: 140) == false)
        #expect(range.admits(count: 29) == false)
        #expect(range.admits(count: 191) == false)
    }

    @Test func threeCategoriesHaveNoLattice() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile(counts: [4, 3, 3]),
            second: try MarginalProfile(counts: [3, 4, 3])
        )
        #expect(range.step == nil)
        #expect(range.attainableCounts == nil)
        #expect(range.upperCount == 3 + 3 + 3)
        #expect(range.lowerCount == 0)
        #expect(range.admits(count: 5) == nil)
        #expect(range.admits(count: 11) == false)
        #expect(throws: PanelDesignError.latticeRequiresBinary(categoryCount: 3)) {
            _ = try range.snap(rate: 0.5)
        }
    }

    /// The hole enumeration found: five items, three categories, identical margins.
    @Test func identicalMarginsForbidASingleDisagreement() throws {
        let profile = try MarginalProfile(counts: [1, 2, 2])
        let range = try AttainableAgreement(first: profile, second: profile)
        #expect(range.marginsAreIdentical)
        #expect(range.lowerCount == 0)
        #expect(range.upperCount == 5)
        #expect(range.admits(count: 4) == false)
        #expect(range.admits(count: 3) == nil)
        #expect(Enumeration.traces(rows: [1, 2, 2], columns: [1, 2, 2]) == [0, 1, 2, 3, 5])
    }

    /// The same exclusion, at every category count enumeration can reach.
    @Test(arguments: [2, 3, 4]) func oneDisagreementIsNeverPossible(categories: Int) throws {
        let items = categories == 4 ? 5 : 6
        for counts in Enumeration.compositions(total: items, parts: categories) {
            let profile = try MarginalProfile(counts: counts)
            let range = try AttainableAgreement(first: profile, second: profile)
            #expect(range.admits(count: items - 1) == false)
            #expect(!Enumeration.traces(rows: counts, columns: counts).contains(items - 1))
        }
    }

    @Test func snappingReportsTheNearestExistingCount() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile.binary(positives: 121, items: 200),
            second: try MarginalProfile.binary(positives: 110, items: 200)
        )
        #expect(try range.snap(rate: 0.705) == 141)
        #expect(try range.snap(rate: 0.700) == 141)
        #expect(try range.snap(rate: 0.710) == 143)
        #expect(try range.snap(rate: range.lower) == range.lowerCount)
        #expect(try range.snap(rate: range.upper) == range.upperCount)
    }

    @Test func aRateOutsideTheRangeIsRefusedRatherThanClamped() throws {
        let range = try AttainableAgreement(
            first: try MarginalProfile.binary(positives: 121, items: 200),
            second: try MarginalProfile.binary(positives: 110, items: 200)
        )
        #expect(throws: PanelDesignError.rateOutsideAttainableRange(
            requested: 0.10, lower: 0.155, upper: 0.945
        )) {
            _ = try range.snap(rate: 0.10)
        }
        #expect(throws: PanelDesignError.rateOutsideAttainableRange(
            requested: 0.99, lower: 0.155, upper: 0.945
        )) {
            _ = try range.snap(rate: 0.99)
        }
    }

    @Test func mismatchedMarginsAreRefused() throws {
        #expect(throws: PanelDesignError.itemCountMismatch(first: 10, second: 12)) {
            _ = try AttainableAgreement(
                first: try MarginalProfile(counts: [5, 5]),
                second: try MarginalProfile(counts: [6, 6])
            )
        }
    }

    /// The closed forms, checked against every table the margins admit.
    @Test(arguments: [2, 3, 4]) func boundsMatchExhaustiveEnumeration(categories: Int) throws {
        let items = categories == 4 ? 5 : 6
        for rows in Enumeration.compositions(total: items, parts: categories) {
            for columns in Enumeration.compositions(total: items, parts: categories) {
                let traces = Enumeration.traces(rows: rows, columns: columns)
                guard !traces.isEmpty else { continue }
                let range = try AttainableAgreement(
                    first: try MarginalProfile(counts: rows),
                    second: try MarginalProfile(counts: columns)
                )
                #expect(traces.min() == range.lowerCount)
                #expect(traces.max() == range.upperCount)
                if let lattice = range.attainableCounts {
                    #expect(Set(lattice) == traces)
                }
                for count in range.lowerCount...range.upperCount where range.admits(count: count) == false {
                    #expect(!traces.contains(count))
                }
            }
        }
    }
}
