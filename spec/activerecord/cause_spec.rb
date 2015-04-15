require 'spec_helper'

describe ActiveRecord::Cause do
  let(:stringio) { StringIO.new }
  let(:logger) { Logger.new(stringio) }
  before do
    ActiveRecord::Base.logger = logger
  end

  context "If caused by path that matches `match_paths`" do
    before do
      ActiveRecord::Cause.match_paths = [/_spec/]
    end

    it 'Log SQL with location that is cause of load' do
      User.all.to_a
      expect(stringio.tap(&:rewind).read).to match(/#{File.expand_path(__FILE__)}/)
    end
  end

  context "Unless caused by path that matches `match_paths`" do
    before do
      ActiveRecord::Cause.match_paths = [/hogehoge/]
    end

    it 'Log SQL with location that is cause of load' do
      User.all.to_a
      expect(stringio.tap(&:rewind).read).not_to match(/#{File.expand_path(__FILE__)}/)
    end
  end
end
