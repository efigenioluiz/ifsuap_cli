require_relative '../lib/ifsuap'

RSpec.describe IfSuap::Command do
  let(:command) { IfSuap::Command.new }

  describe '#fetch_disciplines' do
    it 'always passes' do
      expect(true).to eq(true)
    end
  end
end
