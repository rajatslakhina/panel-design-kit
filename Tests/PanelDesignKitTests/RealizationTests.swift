import Testing
@testable import PanelDesignKit

@Suite("Realising a design")
struct RealizationTests {

    @Test func aTableBecomesTwoLabelVectors() throws {
        let table = try JointTable(cells: [[71, 29], [29, 71]])
        let realisation = PanelRealization(table: table, seed: 20_260_907)
        #expect(realisation.itemCount == 200)
        #expect(realisation.categoryCount == 2)
        let matrix = try realisation.matrix()
        #expect(try matrix.table(0, 1).cells == table.cells)
    }

    @Test func theSeedIsTheWholeDifference() throws {
        let table = try JointTable(cells: [[71, 29], [29, 71]])
        let first = PanelRealization(table: table, seed: 1)
        let second = PanelRealization(table: table, seed: 1)
        let third = PanelRealization(table: table, seed: 2)
        #expect(first == second)
        #expect(first != third)
        #expect(try third.matrix().table(0, 1).cells == table.cells)
    }

    @Test func theGeneratorIsDeterministic() {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        #expect(first.next() == second.next())
        #expect(first.next() == second.next())
    }
}
