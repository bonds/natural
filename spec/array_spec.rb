require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Array, "#to_ranges" do
  it "returns [1..4, 7..8, 9..12] for [1, 12, 6, 2, 3, 4, 11, 9, 10, 7]" do
    [1, 12, 6, 2, 3, 4, 11, 9, 10, 7].to_ranges == [1..4, 6..7, 9..12]
  end
end
