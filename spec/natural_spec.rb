require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Natural" do
  it "recognizes synonyms on top of misspellings" do
    logger = double("logger")
    logger.should_receive(:info).with("[n][orig] how many days of the wek beginn with the letter T")
    logger.should_receive(:info).with("[n][used] how many days of the week start with the letter t")
    logger.should_receive(:debug).any_number_of_times
    Natural.new('how many days of the wek beginn with the letter T', :logger => logger).answer.should eq(2)
  end

  it "expands movies into blu-rays" do
    logger = double("logger")
    logger.should_receive(:info).any_number_of_times
    logger.should_receive(:debug).with("[n][scor] 01 blu-rays").at_least(1).times
    logger.should_receive(:debug).any_number_of_times
    Natural.new('movies', :logger => logger)
  end
end
