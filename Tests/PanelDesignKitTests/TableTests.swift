import Testing
@testable import PanelDesignKit

@Suite("Joint tables")
struct TableTests {

    @Test func readingsComeOffTheTable() throws {
        let table = try JointTable(cells: [[67, 54], [43, 36]])
        #expect(table.itemCount == 200)
        #expect(table.categoryCount == 2)
        #expect(table.rowMargin.counts == [121, 79])
        #expect(table.columnMargin.counts == [110, 90])
        #expect(table.diagonalTotal == 103)
        #expect(table.agreementRate == 0.515)
        #expect(abs(table.expectedCount(row: 0, column: 0) - 66.55) < 1e-12)
        #expect(abs(table.maximumIndependenceDeviation - 0.45) < 1e-12)
        #expect(!table.isExactlyIndependent)
        #expect(abs(table.expectedAgreement - 0.5105) < 1e-12)
    }

    @Test func shapeIsChecked() {
        #expect(throws: PanelDesignError.categoryCountTooSmall(1)) {
            _ = try JointTable(cells: [[4]])
        }
        #expect(throws: PanelDesignError.tableNotSquare(rows: 2, columns: 3)) {
            _ = try JointTable(cells: [[1, 2, 3], [4, 5, 6]])
        }
        #expect(throws: PanelDesignError.negativeCount(category: 1, count: -1)) {
            _ = try JointTable(cells: [[4, 4], [-1, 4]])
        }
        #expect(throws: PanelDesignError.itemCountTooSmall(1)) {
            _ = try JointTable(cells: [[1, 0], [0, 0]])
        }
    }

    @Test func anExactlyIndependentTableReadsZero() throws {
        let table = try JointTable(cells: [[50, 50], [50, 50]])
        #expect(table.maximumIndependenceDeviation == 0)
        #expect(table.isExactlyIndependent)
        #expect(table.cohenKappa == 0)
    }

    @Test func kappaHasNoDenominatorOnAOneCategoryPanel() throws {
        let table = try JointTable(cells: [[4, 0], [0, 0]])
        #expect(table.expectedAgreement == 1)
        #expect(table.cohenKappa == nil)
    }

    @Test func oddsRatioIsBinaryAndFinite() throws {
        #expect(try JointTable(cells: [[71, 29], [29, 71]]).oddsRatio() == 71 * 71 / (29.0 * 29))
        #expect(throws: PanelDesignError.oddsRatioRequiresBinary(categoryCount: 3)) {
            _ = try JointTable(cells: [[2, 1, 1], [1, 2, 1], [1, 1, 2]]).oddsRatio()
        }
        #expect(throws: PanelDesignError.oddsRatioUndefined(row: 0, column: 1)) {
            _ = try JointTable(cells: [[100, 0], [40, 60]]).oddsRatio()
        }
        #expect(throws: PanelDesignError.oddsRatioUndefined(row: 1, column: 0)) {
            _ = try JointTable(cells: [[100, 40], [0, 60]]).oddsRatio()
        }
    }

    @Test func theMaximumDiagonalTableIsBuiltRatherThanAsserted() throws {
        let first = try MarginalProfile(counts: [4, 3, 3])
        let second = try MarginalProfile(counts: [3, 4, 3])
        let table = try JointTable.maximumDiagonal(first: first, second: second)
        #expect(table.rowMargin.counts == first.counts)
        #expect(table.columnMargin.counts == second.counts)
        let range = try AttainableAgreement(first: first, second: second)
        #expect(table.diagonalTotal == range.upperCount)
    }

    @Test func identicalMarginsNeedNoSurplusRouting() throws {
        let profile = try MarginalProfile(counts: [5, 5])
        let table = try JointTable.maximumDiagonal(first: profile, second: profile)
        #expect(table.cells == [[5, 0], [0, 5]])
        #expect(table.diagonalTotal == 10)
    }

    @Test func maximumDiagonalRefusesIncomparableMargins() throws {
        #expect(throws: PanelDesignError.itemCountMismatch(first: 10, second: 12)) {
            _ = try JointTable.maximumDiagonal(
                first: try MarginalProfile(counts: [5, 5]),
                second: try MarginalProfile(counts: [6, 6])
            )
        }
    }

    /// Attainment, checked over every margin pair small enough to enumerate.
    @Test(arguments: [2, 3]) func maximumDiagonalAlwaysAttainsTheCeiling(categories: Int) throws {
        for rows in Enumeration.compositions(total: 6, parts: categories) {
            for columns in Enumeration.compositions(total: 6, parts: categories) {
                let first = try MarginalProfile(counts: rows)
                let second = try MarginalProfile(counts: columns)
                let table = try JointTable.maximumDiagonal(first: first, second: second)
                let range = try AttainableAgreement(first: first, second: second)
                #expect(table.rowMargin.counts == rows)
                #expect(table.columnMargin.counts == columns)
                #expect(table.diagonalTotal == range.upperCount)
            }
        }
    }
}
