import Testing
@testable import PanelDesignKit

@Suite("Building a binary fixture")
struct BuilderTests {

    private func builder(_ firstPositives: Int = 121, _ secondPositives: Int = 110) throws -> BinaryPanelBuilder {
        try BinaryPanelBuilder(
            first: try MarginalProfile.binary(positives: firstPositives, items: 200),
            second: try MarginalProfile.binary(positives: secondPositives, items: 200)
        )
    }

    @Test func everyAttainableCountProducesATableWithTheRightMargins() throws {
        let built = try builder()
        for count in try #require(built.attainable.attainableCounts) {
            let table = try built.table(diagonalTotal: count)
            #expect(table.diagonalTotal == count)
            #expect(table.rowMargin.counts == [121, 79])
            #expect(table.columnMargin.counts == [110, 90])
        }
    }

    @Test func countsOffTheLatticeDoNotExist() throws {
        let built = try builder()
        #expect(throws: PanelDesignError.rateOutsideAttainableRange(
            requested: 0.5, lower: 0.155, upper: 0.945
        )) {
            _ = try built.table(diagonalTotal: 100)
        }
        #expect(throws: PanelDesignError.rateOutsideAttainableRange(
            requested: 0.005, lower: 0.155, upper: 0.945
        )) {
            _ = try built.table(diagonalTotal: 1)
        }
    }

    @Test func anIndependenceTargetLandsOffExactOnAnIntegerPanel() throws {
        let construction = try builder().table(for: .independence)
        #expect(construction.diagonalTotal == 103)
        #expect(abs(construction.requestedDiagonal - 102.1) < 1e-12)
        #expect(abs(construction.snapDistance - 0.0045) < 1e-12)
        #expect(abs(construction.table.maximumIndependenceDeviation - 0.45) < 1e-12)
        #expect(construction.target == .independence)
        #expect(construction.agreementRate == 0.515)
    }

    @Test func anIndependenceTargetIsExactWhenTheProductDivides() throws {
        let construction = try builder(120, 110).table(for: .independence)
        #expect(construction.snapDistance == 0)
        #expect(construction.table.maximumIndependenceDeviation == 0)
        #expect(construction.table.isExactlyIndependent)
    }

    @Test func anOddsRatioTargetIsReproducedToTheLattice() throws {
        let construction = try builder().table(for: .oddsRatio(4))
        #expect(construction.diagonalTotal == 133)
        let realised = try construction.table.oddsRatio()
        #expect(abs(realised - 3.8297) < 1e-4)
        #expect(construction.snapDistance < 0.005)
    }

    @Test func anOddsRatioOfOneIsTheIndependenceTarget() throws {
        let byRatio = try builder().table(for: .oddsRatio(1))
        let byName = try builder().table(for: .independence)
        #expect(byRatio.table == byName.table)
    }

    @Test func anAgreementTargetSnapsToTheNearestExistingRate() throws {
        let construction = try builder().table(for: .agreementRate(0.70))
        #expect(construction.agreementRate == 0.705)
        #expect(abs(construction.snapDistance - 0.005) < 1e-12)
    }

    @Test func targetsOutsideTheRangeAreRefused() throws {
        #expect(throws: PanelDesignError.rateOutsideAttainableRange(
            requested: 0.10, lower: 0.155, upper: 0.945
        )) {
            _ = try builder().table(for: .agreementRate(0.10))
        }
    }

    @Test func aNonPositiveOddsRatioIsRefused() throws {
        #expect(throws: PanelDesignError.oddsRatioNotPositive(0)) {
            _ = try builder().table(for: .oddsRatio(0))
        }
        #expect(throws: PanelDesignError.oddsRatioNotPositive(-3)) {
            _ = try builder().table(for: .oddsRatio(-3))
        }
    }

    @Test func moreThanTwoCategoriesIsRefused() throws {
        #expect(throws: PanelDesignError.constructionRequiresBinary(categoryCount: 3)) {
            _ = try BinaryPanelBuilder(
                first: try MarginalProfile(counts: [4, 3, 3]),
                second: try MarginalProfile(counts: [3, 4, 3])
            )
        }
    }

    @Test func aConstantJudgeIsRefusedOnEitherSide() throws {
        #expect(throws: PanelDesignError.degenerateMarginal(judge: 0, category: 0)) {
            _ = try builder(200, 110)
        }
        #expect(throws: PanelDesignError.degenerateMarginal(judge: 1, category: 1)) {
            _ = try builder(110, 0)
        }
    }

    @Test func incomparableMarginsAreRefusedBeforeAnythingElse() throws {
        #expect(throws: PanelDesignError.itemCountMismatch(first: 200, second: 100)) {
            _ = try BinaryPanelBuilder(
                first: try MarginalProfile.binary(positives: 121, items: 200),
                second: try MarginalProfile.binary(positives: 50, items: 100)
            )
        }
    }
}
