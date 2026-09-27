# frozen_string_literal: true

RSpec.describe RE2::Regexp do
  it "can match an embedded string while the heap is compacted" do
    re = RE2::Regexp.new(("(a?)" * 300) + ("a" * 300))
    text = "a" * 300
    stop = false

    matchers = 4.times.map do
      Thread.new do
        re.match(+text) until stop

        re.match(+text).begin(0)
      end
    end

    100.times { GC.verify_compaction_references(toward: :empty) }
    stop = true

    expect(matchers.map(&:value)).to all(eq(0))
  end
end
