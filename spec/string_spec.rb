require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe String, "#plural?" do
  it "returns false for 'car'" do
    'car'.plural?
  end
  it "returns true for 'cars'" do
    'cars'.plural?
  end
end
